// Copyright © 2024 Apple Inc.

import Foundation
@preconcurrency import Hub
import MLX
import MLXNN
import MLXRandom
import Tokenizers

func prepareModelDirectory(
    hub: HubApi, configuration: ModelConfiguration,
    progressHandler: @Sendable @escaping (Progress) -> Void
) async throws -> URL {
    if let directory = configuration.overrideDirectory {
        return directory
    }

    // download the model weights
    let repo = Hub.Repo(id: configuration.id)
    let modelFiles = ["*.safetensors", "config.json"]
    do {
        return try await hub.snapshot(
            from: repo, matching: modelFiles, progressHandler: progressHandler)
    } catch Hub.HubClientError.authorizationRequired {
        // an authorizationRequired means (typically) that the named repo doesn't exist on
        // on the server so retry with local only configuration
        // For struct ModelConfiguration, we don't have a 'local only' fallback method
        // unless we assume a default location.
        // But overrideDirectory handles explicit local paths.
        // We will just rethrow for now or handle if we want to guess path.
        throw error
    } catch {
        let nserror = error as NSError
        if nserror.domain == NSURLErrorDomain && nserror.code == NSURLErrorNotConnectedToInternet {
             // We can't fall back easily without a known local path strategy.
             // But existing implementations rely on Hub to find cached models.
             // If Hub fails, we might check cache?
             // Hub.snapshot usually checks cache.
             throw error
        } else {
            throw error
        }
    }
}

/// Load and return the model and tokenizer
public func load(
    hub: HubApi = HubApi(), configuration: ModelConfiguration,
    progressHandler: @Sendable @escaping (Progress) -> Void = { _ in }
) async throws -> (LLMModel, Tokenizer) {
    let modelDirectory = try await prepareModelDirectory(
        hub: hub, configuration: configuration, progressHandler: progressHandler)
    let model = try loadSynchronous(modelDirectory: modelDirectory)
    let tokenizer = try await loadTokenizer(configuration: configuration, hub: hub)

    return (model, tokenizer)
}

func loadSynchronous(modelDirectory: URL) throws -> LLMModel {
    // create the model (no weights loaded)
    let configurationURL = modelDirectory.appending(component: "config.json")
    let baseConfig = try JSONDecoder().decode(
        BaseConfiguration.self, from: Data(contentsOf: configurationURL))

    let model = try baseConfig.modelType.createModel(configuration: configurationURL)

    // load the weights
    var weights = [String: MLXArray]()
    let enumerator = FileManager.default.enumerator(
        at: modelDirectory, includingPropertiesForKeys: nil)!
    for case let url as URL in enumerator {
        if url.pathExtension == "safetensors" {
            let w = try loadArrays(url: url)
            for (key, value) in w {
                weights[key] = value
            }
        }
    }

    // per-model cleanup
    weights = model.sanitize(weights: weights)

    // quantize if needed
    if let quantization = baseConfig.quantization {
        quantize(model: model, groupSize: quantization.groupSize, bits: quantization.bits) {
            path, module in
            weights["\(path).scales"] != nil
        }
    }

    // apply the loaded weights
    let parameters = ModuleParameters.unflattened(weights)
    try model.update(parameters: parameters, verify: [.all])

    eval(model)

    return model
}

/// Load and return the model and tokenizer wrapped in a ``ModelContainer`` (provides
/// thread safe access).
public func loadModelContainer(
    hub: HubApi = HubApi(), configuration: ModelConfiguration,
    progressHandler: @Sendable @escaping (Progress) -> Void = { _ in }
) async throws -> ModelContainer {
    let modelDirectory = try await prepareModelDirectory(
        hub: hub, configuration: configuration, progressHandler: progressHandler)
    return try await ModelContainer(
        hub: hub, modelDirectory: modelDirectory, configuration: configuration)
}
