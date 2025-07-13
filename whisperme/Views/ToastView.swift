import SwiftUI

struct ToastView: View {
    let message: String
    let type: ToastType
    @Binding var isShowing: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: type.icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(type.color)
            
            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
            
            Spacer()
            
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isShowing = false
                }
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(PlainButtonStyle())
            .opacity(0.7)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(type.color.opacity(0.3), lineWidth: 1)
        )
        .frame(maxWidth: 300)
    }
}

class ToastWindow: NSWindow {
    let viewModel: ContentViewModel
    
    init(viewModel: ContentViewModel) {
        self.viewModel = viewModel
        
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 100),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        self.isReleasedWhenClosed = false
        self.level = .screenSaver // Very high level to appear above everything
        self.backgroundColor = NSColor.clear
        self.isOpaque = false
        self.hasShadow = false
        self.ignoresMouseEvents = false // Allow interaction with close button
        
        // Position at top right of screen
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let windowWidth: CGFloat = 400
            let windowHeight: CGFloat = 100
            let rightMargin: CGFloat = 20
            let topMargin: CGFloat = 20
            
            let x = screenFrame.maxX - windowWidth - rightMargin
            let y = screenFrame.maxY - windowHeight - topMargin
            
            self.setFrame(NSRect(x: x, y: y, width: windowWidth, height: windowHeight), display: true)
        }
        
        // Set content view
        let hostingView = NSHostingView(rootView: ToastContainer(viewModel: viewModel))
        self.contentView = hostingView
    }
    
    override var canBecomeKey: Bool {
        return false
    }
    
    override var canBecomeMain: Bool {
        return false
    }
    
    func showToast() {
        self.makeKeyAndOrderFront(nil)
        self.orderFrontRegardless()
    }
    
    func hideToast() {
        self.orderOut(nil)
    }
}

// Toast container view that positions the toast in the upper right
struct ToastContainer: View {
    @ObservedObject var viewModel: ContentViewModel
    
    var body: some View {
        ZStack {
            // Invisible background to capture the full screen
            Color.clear
                .ignoresSafeArea(.all)
            
            VStack {
                HStack {
                    Spacer()
                    
                    if viewModel.showToast {
                        ToastView(
                            message: viewModel.toastMessage,
                            type: viewModel.toastType,
                            isShowing: $viewModel.showToast
                        )
                        .transition(.asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .move(edge: .top).combined(with: .opacity)
                        ))
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: viewModel.showToast)
                        .padding(.trailing, 20)
                        .padding(.top, 20)
                    }
                }
                
                Spacer()
            }
        }
        .allowsHitTesting(viewModel.showToast) // Only capture hits when toast is showing
    }
}

#Preview {
    @State var showToast = true
    return VStack(spacing: 16) {
        ToastView(message: "Function call completed successfully", type: .success, isShowing: $showToast)
        ToastView(message: "Weather information retrieved", type: .functionCall, isShowing: $showToast)
        ToastView(message: "Error occurred during processing", type: .error, isShowing: $showToast)
        ToastView(message: "This is an informational message", type: .info, isShowing: $showToast)
    }
    .padding()
    .frame(width: 400, height: 300)
} 