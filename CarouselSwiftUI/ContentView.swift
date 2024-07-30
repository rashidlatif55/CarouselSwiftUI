//
//  ContentView.swift
//  CarouselSwiftUI
//
//  Created by Rashid Latif on 30/07/2024.
//

import SwiftUI

struct ContentView: View {
    @State private var images: [ImageModel] = []
    @State private var index: Int = 0
    @State private var previewImage: UIImage?
    
    var body: some View {
        NavigationStack {
            VStack {
                PreviewImageView(previewImage: $previewImage, index: $index, images: images)
                ImageCarouselView(images: $images, index: $index)
            }
            .background(BackgroundView())
            .task {
                await loadImages()
            }
        }
    }
    
    private func loadImages() async {
        guard images.isEmpty else { return }
        
        for i in 1...35 {
            let imageName = "image_\(i)"
            if let thumbnail = await UIImage(named: imageName)?.byPreparingThumbnail(ofSize: .init(width: 300, height: 300)) {
                images.append(ImageModel(imageName: imageName, thumbnail: thumbnail))
            }
        }
        
        previewImage = UIImage(named: images.first?.imageName ?? "")
    }
}

struct PreviewImageView: View {
    @Binding var previewImage: UIImage?
    @Binding var index: Int
    let images: [ImageModel]
    
    var body: some View {
        GeometryReader { geometry in
            if let previewImage {
                ZStack() {
                    Image(uiImage: previewImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                        .onChange(of: index) { _, newValue in
                            withAnimation(.easeInOut(duration: 0.5)) {
                                self.previewImage = UIImage(named: images[newValue].imageName)
                            }
                        }
                    
                    BlurView(style: .systemUltraThinMaterialLight)
                    //                        .opacity(0.9) // Adjust opacity for lighter blur
                        .ignoresSafeArea()
                    
                    Image(uiImage: previewImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                        .onChange(of: index) { _, newValue in
                            withAnimation(.easeInOut(duration: 0.5)) {
                                self.previewImage = UIImage(named: images[newValue].imageName)
                            }
                        }
                    
                }
                
                
            }
        }
        .padding(.vertical, 15)
    }
}

struct ImageCarouselView: View {
    @Binding var images: [ImageModel]
    @Binding var index: Int
    
    var body: some View {
        GeometryReader { geometry in
            let pageWidth = geometry.size.width / 3
            let imageWidth: CGFloat = 100
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 0) {
                    ForEach(images) { image in
                        if let thumbnail = image.thumbnail {
                            Image(uiImage: thumbnail)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(
                                    width: imageWidth,
                                    height: geometry.size.height
                                )
                                .clipShape(
                                    RoundedRectangle(
                                        cornerRadius: 10,
                                        style: .continuous
                                    )
                                )
                                .frame(
                                    width: pageWidth,
                                    height: geometry.size.height
                                )
                                .onTapGesture {
                                    print("hello")
                                }
                        }
                    }
                }
                .padding(.horizontal, (geometry.size.width - pageWidth) / 2)
                .background {
                    SnapCarouselHelper(pageWidth: pageWidth, pageCount: images.count, index: $index)
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.white, lineWidth: 3)
                    .frame(width: imageWidth, height: geometry.size.height)
            }
        }
        .frame(height: 120)
        .padding(.bottom, 10)
    }
}

struct BackgroundView: View {
    var body: some View {
        Rectangle()
            .fill(Color.black.opacity(0.9).gradient)
            .rotationEffect(.degrees(-180))
            .ignoresSafeArea()
    }
}

struct ImageModel: Identifiable {
    var id = UUID()
    var imageName: String
    var thumbnail: UIImage?
}

struct SnapCarouselHelper: UIViewRepresentable {
    var pageWidth: CGFloat
    var pageCount: Int
    @Binding var index: Int
    
    func makeUIView(context: Context) -> UIView {
        UIView()
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            if let scrollView = findScrollView(in: uiView) {
                scrollView.decelerationRate = .fast
                scrollView.delegate = context.coordinator
                context.coordinator.pageCount = pageCount
                context.coordinator.pageWidth = pageWidth
            }
        }
    }
    
    private func findScrollView(in view: UIView) -> UIScrollView? {
        var currentView: UIView? = view
        while let superview = currentView?.superview {
            if let scrollView = superview as? UIScrollView {
                return scrollView
            }
            currentView = superview
        }
        return nil
    }
    
    class Coordinator: NSObject, UIScrollViewDelegate {
        var parent: SnapCarouselHelper
        var pageCount: Int
        var pageWidth: CGFloat
        
        init(parent: SnapCarouselHelper) {
            self.parent = parent
            self.pageCount = parent.pageCount
            self.pageWidth = parent.pageWidth
        }
        
        func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
            let targetEnd = scrollView.contentOffset.x + (velocity.x * 60)
            let targetIndex = (targetEnd / pageWidth).rounded()
            let index = min(max(Int(targetIndex), 0), pageCount - 1)
            parent.index = index
            targetContentOffset.pointee.x = targetIndex * pageWidth
        }
    }
}

#Preview {
    ContentView()
}


struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style = .light // Customize the style here
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        let blurEffect = UIBlurEffect(style: style)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = view.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(blurEffectView)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // No update needed for static blur
    }
}


