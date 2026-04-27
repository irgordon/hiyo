sed -i 's/var displayName: String/var modelDisplayName: String/g' Hiyo/Sources/Hiyo/UI/Sidebar/ConversationSidebar.swift
sed -i 's/model.displayName/model.modelDisplayName/g' Hiyo/Sources/Hiyo/UI/Sidebar/ConversationSidebar.swift
sed -i 's/provider.currentModel.displayName/provider.currentModel.modelDisplayName/g' Hiyo/Sources/Hiyo/UI/Settings/ModelsSettings.swift
sed -i 's/provider.currentModel.displayName/provider.currentModel.modelDisplayName/g' Hiyo/Sources/Hiyo/UI/Welcome/LoadingStateView.swift
