import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct LibraryView: View {
    @ObservedObject private var library = VideoLibraryStore.shared
    @ObservedObject private var settings = SettingsStore.shared
    @State private var selection: UUID?
    @State private var isImporting = false

    private let columns = [
        GridItem(.adaptive(minimum: 240, maximum: 300), spacing: 16)
    ]

    var body: some View {
        HStack(spacing: 0) {
            sidebar

            Divider()

            VStack(spacing: 0) {
                header
                Divider()
                content
                Divider()
                SettingsView()
                    .padding(16)
                    .background(Color(nsColor: .windowBackgroundColor))
            }
        }
        .frame(minWidth: 860, minHeight: 560)
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear {
            selection = settings.currentVideoID ?? library.videos.first?.id
        }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 28, height: 28)
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                VStack(alignment: .leading, spacing: 1) {
                    Text("LiveWallpaper")
                        .font(.headline)
                    Text("\(library.videos.count) video\(library.videos.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Button(action: importVideos) {
                Label(isImporting ? "Importing..." : "Import Videos", systemImage: "plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isImporting)

            if library.videos.isEmpty {
                Spacer()
                Text("Import .mp4, .mov or .m4v files. The selected video starts as the live wallpaper after login.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(library.videos) { video in
                            VideoListRow(
                                video: video,
                                isSelected: selection == video.id,
                                isCurrent: settings.currentVideoID == video.id
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                setWallpaper(video)
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .padding(16)
        .frame(width: 260)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private var header: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(currentTitle)
                    .font(.headline)
                    .lineLimit(1)
                Text(settings.isPaused ? "Wallpaper paused" : "Wallpaper running")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Picker("Aspect", selection: Binding(
                get: { settings.aspectMode },
                set: { settings.setAspectMode($0) }
            )) {
                ForEach(AspectMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .labelsHidden()
            .pickerStyle(.segmented)
            .frame(width: 132)

            Button {
                settings.setPaused(!settings.isPaused)
            } label: {
                Label(settings.isPaused ? "Resume" : "Pause", systemImage: settings.isPaused ? "play.fill" : "pause.fill")
            }
            .controlSize(.regular)

            Button {
                if let random = library.randomVideo(excluding: settings.currentVideoID) {
                    setWallpaper(random)
                }
            } label: {
                Label("Random", systemImage: "shuffle")
            }
            .controlSize(.regular)
            .disabled(library.videos.isEmpty)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .frame(height: 62)
    }

    @ViewBuilder
    private var content: some View {
        if library.videos.isEmpty {
            EmptyLibraryView(importAction: importVideos)
        } else {
            ScrollView {
                LazyVGrid(columns: columns, alignment: .leading, spacing: 16) {
                    ForEach(library.videos) { video in
                        VideoCard(
                            video: video,
                            isCurrent: settings.currentVideoID == video.id,
                            setWallpaperAction: {
                                setWallpaper(video)
                            },
                            removeAction: {
                                remove(video)
                            }
                        )
                    }
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .background(Color(nsColor: .textBackgroundColor).opacity(0.25))
        }
    }

    private var currentTitle: String {
        if let current = library.video(with: settings.currentVideoID) {
            return current.displayName
        }
        return "No wallpaper selected"
    }

    private func setWallpaper(_ video: WallpaperVideo) {
        selection = video.id
        settings.setCurrentVideo(video.id)
        settings.setPaused(false)
    }

    private func importVideos() {
        let panel = NSOpenPanel()
        panel.title = "Import Videos"
        panel.prompt = "Import"
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true

        var contentTypes: [UTType] = [.mpeg4Movie, .quickTimeMovie]
        if let m4v = UTType(filenameExtension: "m4v") {
            contentTypes.append(m4v)
        }
        panel.allowedContentTypes = contentTypes

        guard panel.runModal() == .OK else { return }

        isImporting = true
        Task {
            let imported = await library.importVideos(from: panel.urls)
            if let first = imported.first {
                setWallpaper(first)
            }
            isImporting = false
        }
    }

    private func remove(_ video: WallpaperVideo) {
        let wasCurrent = settings.currentVideoID == video.id
        library.remove(video)

        if wasCurrent {
            if let replacement = library.videos.first {
                setWallpaper(replacement)
            } else {
                selection = nil
                settings.setCurrentVideo(nil)
            }
        } else if selection == video.id {
            selection = settings.currentVideoID ?? library.videos.first?.id
        }
    }
}

private struct VideoListRow: View {
    let video: WallpaperVideo
    let isSelected: Bool
    let isCurrent: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: isCurrent ? "checkmark.circle.fill" : "film")
                .foregroundStyle(isCurrent ? Color.green : Color.secondary)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 2) {
                Text(video.displayName)
                    .font(.subheadline.weight(isCurrent ? .semibold : .regular))
                    .lineLimit(1)
                Text(formatDuration(video.duration))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(isSelected ? Color.accentColor.opacity(0.18) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 7))
    }
}

private struct VideoCard: View {
    let video: WallpaperVideo
    let isCurrent: Bool
    let setWallpaperAction: () -> Void
    let removeAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .topTrailing) {
                ThumbnailView(video: video)
                    .aspectRatio(16 / 9, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 7))

                if isCurrent {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.white, .green)
                        .font(.title2)
                        .padding(8)
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(video.displayName)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Text(video.originalFileName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text(formatDuration(video.duration))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 8) {
                Button(action: setWallpaperAction) {
                    Label(isCurrent ? "Active" : "Set", systemImage: isCurrent ? "checkmark" : "desktopcomputer")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)

                Button(role: .destructive, action: removeAction) {
                    Label("Remove", systemImage: "trash")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isCurrent ? Color.accentColor.opacity(0.12) : Color(nsColor: .controlBackgroundColor))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(isCurrent ? Color.accentColor.opacity(0.45) : Color.clear, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .contentShape(Rectangle())
        .onTapGesture(perform: setWallpaperAction)
    }
}

private struct ThumbnailView: View {
    let video: WallpaperVideo

    var body: some View {
        Group {
            if let thumbnailURL = video.thumbnailURL,
               let image = NSImage(contentsOf: thumbnailURL) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    Rectangle()
                        .fill(Color.black)
                    Image(systemName: "film")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

private struct EmptyLibraryView: View {
    let importAction: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "play.rectangle.on.rectangle")
                .font(.system(size: 46))
                .foregroundStyle(.secondary)
            Text("No videos imported")
                .font(.title3.weight(.semibold))
            Text("Import an .mp4, .mov or .m4v file. The first imported video is applied immediately.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)
            Button(action: importAction) {
                Label("Import Videos", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

private func formatDuration(_ duration: TimeInterval) -> String {
    guard duration.isFinite else { return "--:--" }
    let totalSeconds = Int(duration.rounded())
    let minutes = totalSeconds / 60
    let seconds = totalSeconds % 60
    return String(format: "%d:%02d", minutes, seconds)
}
