//
//  PanelManager+Expose.swift
//  PanelKit
//
//  Created by Louis D'hauwe on 24/02/2017.
//  Copyright © 2017 Silver Fox. All rights reserved.
//

import Foundation

public extension PanelManager where Self: UIViewController {

	func enterExpose() {
		
		// TODO: only calculate expose for floating panels!
		let (panelFrames, scale) = calculateExposeFrames(with: panels)

		for panelFrame in panelFrames {
			updateFrame(for: panelFrame.panel, to: panelFrame.exposeFrame)
		}
		
		UIView.animate(withDuration: 0.4, delay: 0.0, options: [], animations: {

			self.panelContentWrapperView.layoutIfNeeded()
			
			for panelFrame in panelFrames {
				
				panelFrame.panel.view.transform = CGAffineTransform(scaleX: scale, y: scale)
				
			}
			
		})
		
	}
	
	func exitExpose() {
	
		UIView.animate(withDuration: 0.4, delay: 0.0, options: [], animations: {
			
			self.panelContentWrapperView.layoutIfNeeded()
//
//			for panelFrame in panelFrames {
//				
//				panelFrame.panel.view.transform = .identity
//				
//			}
			
		})
		
	}
	
}

extension PanelManager where Self: UIViewController {
	
	func calculateExposeFrames(with panels: [PanelViewController]) -> ([PanelFrame], CGFloat) {
		
		let panelFrames: [PanelFrame] = panels.map { (p) -> PanelFrame in
			return PanelFrame(panel: p)
		}
		
		distribute(panelFrames)
		
		let unionFrame = unionRect(with: panelFrames)
		print("unionFrame: \(unionFrame)")
		
		for r in panelFrames {
			
			r.exposeFrame.origin.x -= unionFrame.origin.x
			r.exposeFrame.origin.y -= unionFrame.origin.y
			
		}
		
		var normalizedUnionFrame = unionFrame
		normalizedUnionFrame.origin.x = 0.0
		normalizedUnionFrame.origin.y = 0.0
		
		print("normalizedUnionFrame: \(normalizedUnionFrame)")
		
		let padding: CGFloat = 44.0
		
		let scale = min(1.0, min(((self.view.frame.width - padding) / unionFrame.width), ((self.view.frame.height - padding) / unionFrame.height)))
		
		print("scale: \(scale)")
		
		
		var scaledNormalizedUnionFrame = normalizedUnionFrame
		scaledNormalizedUnionFrame.size.width *= scale
		scaledNormalizedUnionFrame.size.height *= scale
		
		print("scaledNormalizedUnionFrame: \(scaledNormalizedUnionFrame)")
		
		for r in panelFrames {
			
			r.exposeFrame.origin.x *= scale
			r.exposeFrame.origin.y *= scale
			
			let width = r.exposeFrame.size.width
			let height = r.exposeFrame.size.height
			
			r.exposeFrame.origin.x -= width * (1.0 - scale) / 2
			r.exposeFrame.origin.y -= height * (1.0 - scale) / 2
			
			// Center
			
			r.exposeFrame.origin.x += (max(self.view.frame.width - scaledNormalizedUnionFrame.width, 0.0)) / 2.0
			r.exposeFrame.origin.y += (max(self.view.frame.height - scaledNormalizedUnionFrame.height, 0.0)) / 2.0
			
		}
		
		return (panelFrames, scale)
		
	}
	
	func doRectanglesIntersect(_ rectangles: [PanelFrame]) -> Bool {
		
		for r1 in rectangles {
			
			for r2 in rectangles {
				if r1 === r2 {
					continue
				}
				
				if r1.exposeFrame.intersects(r2.exposeFrame) {
					return true
				}
				
			}
			
		}
		
		return false
		
	}
	
	func numberOfIntersections(of rectangle: PanelFrame, with rectangles: [PanelFrame]) -> Int {
		
		var intersections = 0
		
		let r1 = rectangle
		
		for r2 in rectangles {
			if r1 === r2 {
				continue
			}
			
			if r1.exposeFrame.intersects(r2.exposeFrame) {
				intersections += 1
			}
			
		}
		
		return intersections
	}
	
	func unionRect(with rectangles: [PanelFrame]) -> CGRect {
		
		var rect = rectangles.first!.exposeFrame
		
		for r in rectangles {
			
			rect = rect.union(r.exposeFrame)
			
		}
		
		return rect
		
	}
	
	func distribute(_ rectangles: [PanelFrame]) {
		
		var rectangles = rectangles
		
		var stack = [PanelFrame]()
		
		while doRectanglesIntersect(rectangles) {
			
			var sortedRectangles = rectangles.sorted(by: { (r1, r2) -> Bool in
				let n1 = numberOfIntersections(of: r1, with: rectangles)
				let n2 = numberOfIntersections(of: r2, with: rectangles)
				return n1 > n2
			})
			
			let mostIntersected = sortedRectangles[0]
			
			stack.append(mostIntersected)
			
			rectangles.remove(at: rectangles.index(where: { (r) -> Bool in
				r === mostIntersected
			})!)
			
		}
		
		while !stack.isEmpty {
			
			let last = stack.popLast()!
			
			rectangles.append(last)
			
			let unionRect = self.unionRect(with: rectangles)
			let g = CGPoint(x: unionRect.midX, y: unionRect.midY)
			
			let deltaX = last.panel.view.center.x - g.x
			let deltaY = last.panel.view.center.y - g.y
			
			while numberOfIntersections(of: last, with: rectangles) > 0 {
				
				last.exposeFrame.origin.x += deltaX / 20.0
				last.exposeFrame.origin.y += deltaY / 20.0
				
			}
			
		}
		
	}
	
}

class PanelFrame {
	
	let panel: PanelViewController
	var exposeFrame: CGRect
	
	init(panel: PanelViewController) {
		self.panel = panel
		self.exposeFrame = panel.view.frame
	}
	
}