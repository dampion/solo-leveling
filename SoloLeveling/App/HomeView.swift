import SwiftUI

struct HomeView: View {
    @ObservedObject var model: AppModel
    @State private var showingSettings = false
    @State private var selectedProject: SideProject?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("你的個人成長基地").font(.subheadline).foregroundStyle(.cyan)
                        Text("歡迎回來").font(.largeTitle.bold())
                        Text("累積每一次開始，打造自己的作品。").foregroundStyle(.secondary)
                    }
                    VStack(alignment: .leading, spacing: 18) {
                        Label("連續登入", systemImage: "flame.fill")
                            .font(.headline).foregroundStyle(.cyan)
                        HStack(alignment: .firstTextBaseline, spacing: 12) {
                            Text("\(model.streak.days)")
                                .font(.system(size: 76, weight: .bold, design: .rounded))
                                .contentTransition(.numericText())
                            Text("天").font(.title2).foregroundStyle(.secondary)
                        }
                        Divider()
                        Text("上次登入").font(.caption).foregroundStyle(.secondary)
                        if let previous = model.previousLogin {
                            Text(previous.formatted(date: .abbreviated, time: .shortened))
                        } else {
                            Text("這是你的第一次登入")
                        }
                        Text("每滿 24 小時最多累加一次；超過 24 小時未登入，重新從第 1 天開始。")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(26)
                    .background(.cyan.opacity(0.08), in: RoundedRectangle(cornerRadius: 28))
                    .overlay(RoundedRectangle(cornerRadius: 28).stroke(.cyan.opacity(0.2)))
                    Label("從右下角選單，開啟你的 Side Project。", systemImage: "square.stack.3d.up")
                        .font(.callout).foregroundStyle(.secondary)
                }
                .padding(24)
                .frame(maxWidth: 600)
                .frame(maxWidth: .infinity)
            }
            .background(Color(red: 0.035, green: 0.045, blue: 0.08))
            .navigationTitle("Solo Leveling")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingSettings = true } label: {
                        Image(systemName: "gearshape")
                    }.accessibilityLabel("設定")
                }
            }
            .safeAreaInset(edge: .bottom) {
                HStack {
                    Spacer()
                    Menu {
                        ForEach(SideProject.allCases) { project in
                            Button { selectedProject = project } label: {
                                Label(project.title, systemImage: project.symbol)
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.title2.bold()).foregroundStyle(.black)
                            .frame(width: 60, height: 60)
                            .background(.cyan, in: Circle())
                    }
                    .accessibilityLabel("更多專案")
                }.padding(.horizontal, 24).padding(.bottom, 16)
            }
            .sheet(isPresented: $showingSettings) { SettingsView(model: model) }
            .fullScreenCover(item: $selectedProject) { ProjectBrowser(project: $0) }
        }
    }
}

struct SettingsView: View {
    @ObservedObject var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var oldPIN = ""
    @State private var newPIN = ""
    @State private var confirmation = ""
    @State private var saved = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("使用 Face ID 解鎖", isOn: Binding(
                        get: { model.faceIDEnabled },
                        set: { model.setFaceIDEnabled($0) }
                    )).disabled(model.isAuthenticating)
                    if model.isAuthenticating { ProgressView("正在驗證 Face ID…") }
                } footer: {
                    Text("啟用前會驗證 Face ID。驗證失敗或取消時，仍可使用 App 密碼。")
                }
                Section("修改 App 密碼") {
                    PINField(title: "目前密碼", value: $oldPIN)
                    PINField(title: "新密碼（4 位數字）", value: $newPIN)
                    PINField(title: "再次輸入新密碼", value: $confirmation)
                    Button("儲存新密碼") {
                        saved = model.changePIN(old: oldPIN, new: newPIN, confirmation: confirmation)
                        if saved { oldPIN = ""; newPIN = ""; confirmation = "" }
                    }.disabled(!PINRules.isValid(oldPIN) || !PINRules.isValid(newPIN)
                               || !PINRules.isValid(confirmation))
                }
                if let message = model.errorMessage {
                    Section { Text(message).foregroundStyle(.orange) }
                }
                Section("關於") {
                    LabeledContent("App", value: "Solo Leveling")
                    Text("登入紀錄與網站資料儲存在此裝置，不與 Safari 共用。")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("設定")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("完成") { dismiss() } } }
            .onAppear { model.errorMessage = nil }
            .alert("密碼已更新", isPresented: $saved) { Button("好", role: .cancel) {} }
        }
    }
}
