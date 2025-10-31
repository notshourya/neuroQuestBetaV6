//
//  PencilCanvasHelper.swift
//  neuroQuest
//
//  Created by Shourya Thakur on 10/30/25.
//


import SwiftUI
import PencilKit


struct PencilKitCanvasView: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    @Binding var selectedColor: Color
    @Binding var selectedWidth: CGFloat
    @Binding var undoManager: UndoManager? 

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> PKCanvasView {
        let canvasView = PKCanvasView()
        canvasView.drawingPolicy = .anyInput
        canvasView.delegate = context.coordinator
        canvasView.drawing = drawing
        updateTool(canvasView: canvasView)
        DispatchQueue.main.async {
            self.undoManager = canvasView.undoManager
        }
        
        return canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        if uiView.drawing.dataRepresentation() != drawing.dataRepresentation() {
            uiView.drawing = drawing
        }
        if self.undoManager !== uiView.undoManager {
             DispatchQueue.main.async {
                  self.undoManager = uiView.undoManager
             }
        }
        updateTool(canvasView: uiView)
    }

    private func updateTool(canvasView: PKCanvasView) {
        let inkType: PKInkingTool.InkType = .pen
        canvasView.tool = PKInkingTool(
            inkType,
            color: UIColor(selectedColor),
            width: selectedWidth
        )
    }

    class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: PencilKitCanvasView
        init(_ parent: PencilKitCanvasView) { self.parent = parent }
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            if parent.drawing.dataRepresentation() != canvasView.drawing.dataRepresentation() {
                parent.drawing = canvasView.drawing
            }
        }
    }
}
