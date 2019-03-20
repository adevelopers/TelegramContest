//
//  YAxisOverlayView.swift
//  TelegramContest
//
//  Created by Alexander Zimin on 18/03/2019.
//  Copyright © 2019 alex. All rights reserved.
//

import UIKit

class YAxisView: UIView {
    var label: UILabel = UILabel()
    var line: UIView = UIView()

    var theme: Theme = .light {
        didSet {
            let config = theme.configuration
            self.label.textColor = config.titleColor
            self.line.backgroundColor = config.lineColor
        }
    }

    init() {
        super.init(frame: .zero)
        self.setup()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var frame: CGRect {
        didSet {
            self.line.frame = CGRect(x: 0, y: 25, width: self.frame.width, height: 0.5)
        }
    }

    func setup() {
        self.label.font = UIFont.systemFont(ofSize: 12)
        self.label.textAlignment = .left
        self.label.frame = CGRect(x: 0, y: 0, width: 60, height: 26)

        self.line.frame = CGRect(x: 0, y: 25, width: self.frame.width, height: 0.5)
        self.line.backgroundColor = UIColor.black.withAlphaComponent(0.3)

        self.addSubview(self.label)
        self.addSubview(self.line)
    }
}

class YAxisOverlayView: UIView {
    struct Item {
        var view: YAxisView
        var value: Int
    }

    var maxValue: Int = 0
    var items: [Item] = []
    var onRemoving: [YAxisView] = []

    var theme: Theme = .light {
        didSet {
            self.items.forEach({ $0.view.theme = theme })
        }
    }

    func update(value: Int, animated: Bool) {
        let step = (value / 5)
        let maxValue = step * 5
        let oldValue = self.maxValue

        guard oldValue != maxValue, maxValue != 0 else {
            return
        }

        self.maxValue = maxValue
        self.disapear(animated: animated)
        self.animate(step: step, from: oldValue, animated: animated)
    }

    private func disapear(animated: Bool) {
        self.onRemoving.forEach({ $0.removeFromSuperview() })
        self.onRemoving = []

        for item in self.items {
            let percent = CGFloat(item.value) / CGFloat(self.maxValue)
            self.onRemoving.append(item.view)
            UIView.animate(withDuration: animated ? 0.25 : 0, delay: 0, options: [UIView.AnimationOptions.curveEaseOut], animations: {
                item.view.center = CGPoint(x: item.view.center.x, y: self.frame.height * (1 - percent) - item.view.frame.height / 2)
                item.view.alpha = 0
            }, completion: { _ in
                item.view.removeFromSuperview()
            })
        }
        self.items = []
    }

    private var showAction: (() -> Void)?
    private var startTime = 0.0
    private var displayLink: CADisplayLink?

    private func animate(step: Int, from: Int, animated: Bool) {
        self.showAction = {
            for i in 0..<5 {
                let percent = CGFloat(i * step) / CGFloat(self.maxValue)
                let oldPercent: CGFloat
                if from == 0 {
                    oldPercent = 0
                } else {
                    oldPercent = CGFloat(i * step) / CGFloat(from)
                }
                let view = YAxisView()
                view.label.text = "\(step * i)"
                view.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: 26)
                view.alpha = 0
                view.center = CGPoint(x: view.center.x, y: self.frame.height * (1 - oldPercent) - view.frame.height / 2)
                view.theme = self.theme
                self.addSubview(view)
                self.items.append(Item(view: view, value: step * i))

                UIView.animate(withDuration: animated ? 0.25 : 0, delay: 0, options: [UIView.AnimationOptions.curveEaseOut], animations: {
                    view.alpha = 1
                    view.center = CGPoint(x: view.center.x, y: self.frame.height * (1 - percent) - view.frame.height / 2)
                }, completion: nil)

                self.showAction = nil
                self.displayLink?.invalidate()
                self.displayLink = nil
            }
        }

        if displayLink == nil {
            self.startTime = CACurrentMediaTime()
            self.displayLink = CADisplayLink(target: self, selector: #selector(self.displayLinkDidFire(_:)))
            self.displayLink?.add(to: .main, forMode: .common)
        }
    }

    @objc
    func displayLinkDidFire(_ displayLink: CADisplayLink) {
        let elapsed = CACurrentMediaTime() - self.startTime

        if elapsed > 0.001 {
            self.showAction?()
            self.displayLink?.invalidate()
            self.displayLink = nil
        }
    }

}
