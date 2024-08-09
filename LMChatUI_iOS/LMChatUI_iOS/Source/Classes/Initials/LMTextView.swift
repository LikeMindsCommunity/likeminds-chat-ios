//
//  LMTextView.swift
//  LMFramework
//
//  Created by Devansh Mohata on 18/12/23.
//

import UIKit

@IBDesignable
open class LMTextView: UITextView {
    
    open var canPerformActionRestriction: Bool = false
    
    open var placeHolderText: String = "" {
        didSet {
            if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                text = placeHolderText
                textColor = .lightGray
            }
        }
    }
    
    open var numberOfLines: Int {
        invalidateIntrinsicContentSize()
        if let font {
            return Int(intrinsicContentSize.height / font.lineHeight)
        }
        return .zero
    }
    
    open func translatesAutoresizingMaskIntoConstraints() -> Self {
        translatesAutoresizingMaskIntoConstraints = false
        return self
    }
    
    // MARK:- Override textview methods
    open override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if canPerformActionRestriction && (action == #selector(copy(_:)) ||
            action == #selector(paste(_:)) ||
            action == #selector(select(_:)) ||
            action == #selector(selectAll(_:)) ||
            action == #selector(cut(_:)) ||
            action == Selector(("_lookup:")) ||
            action == Selector(("_share:")) ||
            action == Selector(("_translate:")) ||
            action == Selector(("_searchWeb:")) ||
            action == Selector(("_define:"))) {
            return false
        }
        return super.canPerformAction(action, withSender: sender)
    }
    
    public func addDoneButtonOnKeyboard() {
        let doneToolbar: UIToolbar = UIToolbar(frame: CGRect.init(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
        doneToolbar.barStyle = .default
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done: UIBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(doneButtonAction))
        
        let items = [flexSpace, done]
        doneToolbar.items = items
        doneToolbar.sizeToFit()
        
        self.inputAccessoryView = doneToolbar
    }
    
    @objc
    open func doneButtonAction() {
        self.resignFirstResponder()
    }
}
