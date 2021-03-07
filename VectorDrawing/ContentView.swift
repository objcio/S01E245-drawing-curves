//
//  ContentView.swift
//  VectorDrawing
//
//  Created by Chris Eidhof on 22.02.21.
//

import SwiftUI

extension Path {
    var elements: [Element] {
        var result: [Element] = []
        forEach { result.append($0) }
        return result
    }
}

extension Path.Element: Identifiable { // hack
    public var id: String { "\(self)" }
}

struct PathPoint: View {
    var element: Path.Element
    
    func pathPoint(at: CGPoint) -> some View {
        Circle()
            .stroke(Color.black)
            .background(Circle().fill(Color.white))
            .padding(2)
            .frame(width: 14, height: 14)
            .offset(x: at.x-7, y: at.y-7)
    }

    func controlPoint(at: CGPoint) -> some View {
        RoundedRectangle(cornerRadius: 2)
            .stroke(Color.black)
            .background(RoundedRectangle(cornerRadius: 2).fill(Color.white))
            .padding(4)
            .frame(width: 14, height: 14)
            .offset(x: at.x-7, y: at.y-7)
    }

    var body: some View {
        switch element {
        case let .line(point),
             let .move(point):
            pathPoint(at: point)
        case let .quadCurve(to, control), let .curve(to, _, control):
            let mirrored = control.mirrored(relativeTo: to)
            Path { p in
                p.move(to: control)
                p.addLine(to: to)
                p.addLine(to: mirrored)
            }.stroke(Color.gray)
            pathPoint(at: to)
            controlPoint(at: control)
            controlPoint(at: mirrored)
        default:
            EmptyView()
        }
    }
}

struct Points: View {
    var path: Path
    var body: some View {
        ForEach(path.elements) { element in
            PathPoint(element: element)
        }
    }
}

extension Path {
    mutating func update(for state: DragGesture.Value) {
        if !isEmpty, let previous = elements.last {
            var control1: CGPoint? = nil
            switch previous {
            case let .quadCurve(to, control), let .curve(to, _, control):
                control1 = control.mirrored(relativeTo: to)
            default:
                ()
            }
            let isDrag = state.startLocation.distance(to: state.location) > 1
            if isDrag {
                let control = state.location.mirrored(relativeTo: state.startLocation)
                if let c1 = control1 {
                    addCurve(to: state.startLocation, control1: c1, control2: control)
                } else {
                    addQuadCurve(to: state.startLocation, control: control)
                }
            } else {
                if let c1 = control1 {
                    addCurve(to: state.startLocation, control1: c1, control2: state.startLocation)
                } else {
                    addLine(to: state.startLocation)
                }
            }
        } else {
            move(to: state.startLocation)
        }
    }
}

struct Drawing: View {
    @State var path = Path()
    @GestureState var currentDrag: DragGesture.Value? = nil
    
    var livePath: Path {
        var copy = path
        if let state = currentDrag {
            copy.update(for: state)
        }
        return copy
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.white
            livePath.stroke(Color.black, lineWidth: 2)
            Points(path: livePath)
        }.gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .local)
                .updating($currentDrag, body: { (value, state, _) in
                    state = value
                })
                .onEnded { state in
                    path.update(for: state)
                }
        )
    }
}

struct ContentView: View {
    var body: some View {
        Drawing()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
