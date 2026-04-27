sed -i 's/\.accentColor/Color\.accentColor/g' Hiyo/Sources/Hiyo/UI/Sidebar/ConversationRow.swift
sed -i 's/\.stroke(\.accent,/.stroke(Color.accentColor,/g' Hiyo/Sources/Hiyo/UI/Welcome/LoadingStateView.swift
sed -i 's/\.background(\.sidebarBackground)/.background(Color("sidebarBackground", bundle: .module))/g' Hiyo/Sources/Hiyo/UI/Sidebar/ConversationSidebar.swift
