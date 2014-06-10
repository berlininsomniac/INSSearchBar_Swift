//
//  INSSearchBar.swift
//  Berlin Insomniac
//
//  Created by Salánki, Benjámin on 09/06/14.
//  Copyright (c) 2014 Berlin Insomniac. All rights reserved.
//

import UIKit

/**
*  The different states for an INSSearchBarState.
*/

enum INSSearchBarState: Int
{
	/**
	*  The default or normal state. The search field is hidden.
	*/
	
	case Normal
	
	/**
	*  The state where the search field is visible.
	*/
	
	case SearchBarVisible
	
	/**
	*  The state where the search field is visible and there is text entered.
	*/
	
	case SearchBarHasContent
	
	/**
	*  The search bar is transitioning between states.
	*/
	
	case Transitioning
}

/**
*  The delegate is responsible for providing values to the search bar that it can use to determine its size.
*/

protocol INSSearchBarDelegate
{
	/**
	*  The delegate is asked to provide the destination frame for the search bar when the search bar is transitioning to the visible state.
	*
	*  @param searchBar The search bar that will begin transitioning.
	*
	*  @return The frame in the coordinate system of the search bar's superview.
	*/
	
	func destinationFrameForSearchBar(searchBar: INSSearchBar) -> CGRect
	
	/**
	*  The delegate is informed about the imminent state transitioning of the status bar.
	*
	*  @param searchBar        The search bar that will begin transitioning.
	*  @param destinationState The state that the bar will be in once transitioning completes. The current state of the search bar can be queried and will return the state before transitioning.
	*/
	
	func searchBar(searchBar: INSSearchBar, willStartTransitioningToState destinationState: INSSearchBarState)
	
	/**
	*  The delegate is informed about the state transitioning of the status bar that has just occured.
	*
	*  @param searchBar        The search bar that went through state transitioning.
	*  @param destinationState The state that the bar was in before transitioning started. The current state of the search bar can be queried and will return the state after transitioning.
	*/
	
	func searchBar(searchBar: INSSearchBar, didEndTransitioningFromState previousState: INSSearchBarState)
}

let kINSSearchBarInset: CGFloat = 11.0
let kINSSearchBarImageSize: CGFloat = 22.0
let kINSSearchBarAnimationStepDuration: NSTimeInterval = 0.25

/**
*  An animating search bar.
*/

class INSSearchBar : UIView, UITextFieldDelegate, UIGestureRecognizerDelegate
{
	/**
	*  The current state of the search bar.
	*/

	var state: INSSearchBarState = INSSearchBarState.Normal

	/**
	*  The (optional) delegate is responsible for providing values necessary for state change animations of the search bar. @see INSSearchBarDelegate.
	*/

	var delegate: INSSearchBarDelegate?
	
	/**
	*  The borderedframe of the search bar. Visible only when search mode is active.
	*/
	
	let searchFrame: UIView
	
	/**
	*  The text field used for entering search queries. Visible only when search is active.
	*/

	let searchField: UITextField
	
	/**
	*  The image view containing the search magnifying glass icon in white. Visible when search is not active.
	*/
	
	let searchImageViewOff: UIImageView

	/**
	*  The image view containing the search magnifying glass icon in blue. Visible when search is active.
	*/

	let searchImageViewOn: UIImageView

	/**
	*  The image view containing the circle part of the magnifying glass icon in blue.
	*/

	let searchImageCircle: UIImageView
	
	/**
	*  The image view containing the left cross part of the magnifying glass icon in blue.
	*/
	
	let searchImageCrossLeft: UIImageView
	
	/**
	*  The image view containing the right cross part of the magnifying glass icon in blue.
	*/
	
	let searchImageCrossRight: UIImageView

	/**
	*  A gesture recognizer responsible for closing the keyboard once tapped on.
	*
	*	Added to the window's root view controller view and set to allow touches to propagate to that view.
	*/

	let keyboardDismissGestureRecognizer: UITapGestureRecognizer
	
	/**
	*  The frame of the search bar before a transition started. Only set if delegate is not nil.
	*/
	var originalFrame: CGRect
		
	init(frame: CGRect)
	{
		self.searchFrame = UIView(frame: CGRectZero)
		self.searchField = UITextField(frame: CGRectZero)
		self.searchImageViewOff = UIImageView(frame: CGRectZero)
		self.searchImageViewOn = UIImageView(frame: CGRectZero)
		self.searchImageCircle = UIImageView(frame: CGRectZero)
		self.searchImageCrossLeft = UIImageView(frame: CGRectZero)
		self.searchImageCrossRight = UIImageView(frame: CGRectZero)
		self.keyboardDismissGestureRecognizer = UITapGestureRecognizer()
		self.originalFrame = CGRectZero
		
		super.init(frame: frame)

		self.opaque = false
		self.backgroundColor = UIColor.clearColor()
		
		self.searchFrame.frame = self.bounds
		self.searchFrame.opaque = false
		self.searchFrame.backgroundColor = UIColor.clearColor()
		self.searchFrame.autoresizingMask = UIViewAutoresizing.FlexibleWidth | UIViewAutoresizing.FlexibleHeight
		self.searchFrame.layer.masksToBounds = true
		self.searchFrame.layer.cornerRadius = CGRectGetHeight(self.bounds) / 2
		self.searchFrame.layer.borderWidth = 0.5
		self.searchFrame.layer.borderColor = UIColor.clearColor().CGColor
		self.searchFrame.contentMode = UIViewContentMode.Redraw
		
		self.addSubview(self.searchFrame)
		
		self.searchField.frame = CGRect(x: kINSSearchBarInset, y: 3.0, width: CGRectGetWidth(self.bounds) - (2 * kINSSearchBarInset) - kINSSearchBarImageSize, height: CGRectGetHeight(self.bounds) - 6.0)
		self.searchField.borderStyle = UITextBorderStyle.None
		self.searchField.autoresizingMask = UIViewAutoresizing.FlexibleWidth | UIViewAutoresizing.FlexibleHeight
		self.searchField.font = UIFont(name:"AvenirNext-Regular", size:16.0)
		self.searchField.textColor = UIColor(red: 17.0/255.0, green: 190.0/255.0, blue: 227.0/255.0, alpha: 1.0)
		self.searchField.alpha = 0.0
		self.searchField.delegate = self
		
		self.searchFrame.addSubview(self.searchField)
		
		let searchImageViewOnContainerView: UIView = UIView(frame:CGRect(x: CGRectGetWidth(self.bounds) - kINSSearchBarInset - kINSSearchBarImageSize, y: (CGRectGetHeight(self.bounds) - kINSSearchBarImageSize) / 2, width: kINSSearchBarImageSize, height: kINSSearchBarImageSize))
		searchImageViewOnContainerView.autoresizingMask = UIViewAutoresizing.FlexibleLeftMargin | UIViewAutoresizing.FlexibleTopMargin | UIViewAutoresizing.FlexibleBottomMargin
		
		self.searchFrame.addSubview(searchImageViewOnContainerView)
		
		self.searchImageViewOn.frame = searchImageViewOnContainerView.bounds
		self.searchImageViewOn.alpha = 0.0
		self.searchImageViewOn.image = UIImage(named: "NavBarIconSearch_blue")
		
		searchImageViewOnContainerView.addSubview(self.searchImageViewOn)

		self.searchImageCircle.frame = CGRect(x: 0.0, y: 0.0, width: 18.0, height: 18.0)
		self.searchImageCircle.alpha = 0.0
		self.searchImageCircle.image = UIImage(named: "NavBarIconSearchCircle_blue")
		
		searchImageViewOnContainerView.addSubview(self.searchImageCircle)

		self.searchImageCrossLeft.frame = CGRect(x: 14.0, y: 14.0, width: 8.0, height: 8.0)
		self.searchImageCrossLeft.alpha = 0.0
		self.searchImageCrossLeft.image = UIImage(named: "NavBarIconSearchBar_blue")
		
		searchImageViewOnContainerView.addSubview(self.searchImageCrossLeft)

		self.searchImageCrossRight.frame = CGRect(x: 7.0, y: 7.0, width: 8.0, height: 8.0)
		self.searchImageCrossRight.alpha = 0.0
		self.searchImageCrossRight.image = UIImage(named: "NavBarIconSearchBar2_blue")
		
		searchImageViewOnContainerView.addSubview(self.searchImageCrossRight)

		self.searchImageViewOff.frame = CGRect(x: CGRectGetWidth(self.bounds) - kINSSearchBarInset - kINSSearchBarImageSize, y: (CGRectGetHeight(self.bounds) - kINSSearchBarImageSize) / 2, width: kINSSearchBarImageSize, height: kINSSearchBarImageSize)
		self.searchImageViewOff.autoresizingMask = UIViewAutoresizing.FlexibleLeftMargin | UIViewAutoresizing.FlexibleTopMargin | UIViewAutoresizing.FlexibleBottomMargin
		self.searchImageViewOff.alpha = 1.0
		self.searchImageViewOff.image = UIImage(named: "NavBarIconSearch_white")
		
		self.searchFrame.addSubview(self.searchImageViewOff)
		
		let tapableView: UIView = UIView(frame: CGRect(x: CGRectGetWidth(self.bounds) - (2 * kINSSearchBarInset) - kINSSearchBarImageSize, y: 0.0, width: (2 * kINSSearchBarInset) + kINSSearchBarImageSize, height: CGRectGetHeight(self.bounds)))
		tapableView.autoresizingMask = UIViewAutoresizing.FlexibleLeftMargin | UIViewAutoresizing.FlexibleHeight
		tapableView.addGestureRecognizer(UITapGestureRecognizer(target:self, action:Selector("changeStateIfPossible:")))
		
		self.searchFrame.addSubview(tapableView)
		
		self.keyboardDismissGestureRecognizer.addTarget(self, action: "dismissKeyboard:")
		self.keyboardDismissGestureRecognizer.cancelsTouchesInView = false
		self.keyboardDismissGestureRecognizer.delegate = self
		
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "textDidChange:", name: UITextFieldTextDidChangeNotification, object: self.searchField)
	}
	
	deinit
	{
		NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
		NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
		NSNotificationCenter.defaultCenter().removeObserver(self, name: UITextFieldTextDidChangeNotification, object: self.searchField)
	}
	
	func changeStateIfPossible(gestureRecognizer: UITapGestureRecognizer)
	{
		switch self.state
		{
			case INSSearchBarState.Normal:
				
				self.showSearchBar(gestureRecognizer)
			
			case INSSearchBarState.SearchBarVisible:
			
				self.hideSearchBar(gestureRecognizer)
			
			case INSSearchBarState.SearchBarHasContent:
			
				self.searchField.text = nil
				self.textDidChange(nil)
			
			default:
			
				break
		}
	}
	
	func dismissKeyboard(gestureRecognizer: UITapGestureRecognizer)
	{
		if (self.searchField.isFirstResponder())
		{
			self.window.endEditing(true)
			
			if (self.state == INSSearchBarState.SearchBarVisible && countElements(self.searchField.text as String) == 0)
			{
				self.hideSearchBar(nil)
			}
		}
	}

	func showSearchBar(sender: AnyObject?)
	{
		if self.state == INSSearchBarState.Normal
		{
			if let delegate = self.delegate
			{
				delegate.searchBar(self, willStartTransitioningToState:INSSearchBarState.SearchBarVisible)
			}
			
			self.state = INSSearchBarState.Transitioning
			
			self.searchField.text = nil
			
			UIView.animateWithDuration(kINSSearchBarAnimationStepDuration, animations: {
				
				self.searchFrame.layer.borderColor = UIColor.whiteColor().CGColor

				if let delegate = self.delegate
				{
					self.originalFrame = self.frame
					self.frame = delegate.destinationFrameForSearchBar(self)
				}
				}, completion: { (finished: Bool) in
					
					self.searchField.becomeFirstResponder()
					
					UIView.animateWithDuration(kINSSearchBarAnimationStepDuration * 2, animations: {
						
						self.searchFrame.layer.backgroundColor = UIColor.whiteColor().CGColor
						self.searchImageViewOff.alpha = 0.0
						self.searchImageViewOn.alpha = 1.0
						self.searchField.alpha = 1.0

						}, completion: { (finished: Bool) in
							
							self.state = INSSearchBarState.SearchBarVisible
							
							if let delegate = self.delegate
							{
								delegate.searchBar(self, didEndTransitioningFromState: INSSearchBarState.Normal)
							}
						})
				})
		}
	}

	func hideSearchBar(sender: AnyObject?)
	{
		if self.state == INSSearchBarState.SearchBarVisible || self.state == INSSearchBarState.SearchBarHasContent
		{
			self.window.endEditing(true)
			
			if let delegate = self.delegate
			{
				delegate.searchBar(self, willStartTransitioningToState: INSSearchBarState.Normal)
			}

			self.searchField.text = nil
			
			self.state = INSSearchBarState.Transitioning
			
			UIView.animateWithDuration(kINSSearchBarAnimationStepDuration, animations: {
				
				if let delegate = self.delegate
				{
					self.frame = self.originalFrame
				}
				
				self.searchFrame.layer.backgroundColor = UIColor.clearColor().CGColor
				self.searchImageViewOff.alpha = 1.0
				self.searchImageViewOn.alpha = 0.0
				self.searchField.alpha = 0.0

				}, completion: { (finished: Bool) in
					
					UIView.animateWithDuration(kINSSearchBarAnimationStepDuration * 2, animations: {
						
						self.searchFrame.layer.borderColor = UIColor.clearColor().CGColor
						
						}, completion: { (finished: Bool) in
							
							self.searchImageCircle.frame = CGRect(x: 0.0, y: 0.0, width: 18.0, height: 18.0)
							self.searchImageCrossLeft.frame = CGRect(x: 14.0, y: 14.0, width: 8.0, height: 8.0)
							self.searchImageCircle.alpha = 0.0
							self.searchImageCrossLeft.alpha = 0.0
							self.searchImageCrossRight.alpha = 0.0
							
							self.state = INSSearchBarState.Normal;
							
							if let delegate = self.delegate
							{
								delegate.searchBar(self, didEndTransitioningFromState: INSSearchBarState.SearchBarVisible)
							}
						})
				})
		}
	}
	
	func textDidChange(notification: NSNotification?)
	{
		var hasText = countElements(self.searchField.text as String) != 0
		
		if hasText
		{
			if self.state == INSSearchBarState.SearchBarVisible
			{
				self.state = INSSearchBarState.Transitioning;
				
				self.searchImageViewOn.alpha = 0.0
				self.searchImageCircle.alpha = 1.0
				self.searchImageCrossLeft.alpha = 1.0
				
				UIView.animateWithDuration(kINSSearchBarAnimationStepDuration, animations: {
					
					self.searchImageCircle.frame = CGRect(x: 2.0, y: 2.0, width: 18.0, height: 18.0)
					self.searchImageCrossLeft.frame = CGRect(x: 7.0, y: 7.0, width: 8.0, height: 8.0)
					
					}, completion: { (finished: Bool) in
						
						UIView.animateWithDuration(kINSSearchBarAnimationStepDuration, animations: {
							
							self.searchImageCrossRight.alpha = 1.0
							
							}, completion: { (finished: Bool) in
								
								self.state = INSSearchBarState.SearchBarHasContent
							})
					})
			}
		}
		else
		{
			if self.state == INSSearchBarState.SearchBarHasContent
			{
				self.state = INSSearchBarState.Transitioning;
				
				UIView.animateWithDuration(kINSSearchBarAnimationStepDuration, animations: {
					
					self.searchImageCrossRight.alpha = 0.0

					}, completion: { (finished: Bool) in
						
						UIView.animateWithDuration(kINSSearchBarAnimationStepDuration, animations: {
							
							self.searchImageCircle.frame = CGRect(x: 0.0, y: 0.0, width: 18.0, height: 18.0)
							self.searchImageCrossLeft.frame = CGRect(x: 14.0, y: 14.0, width: 8.0, height: 8.0)
							
							}, completion: { (finished: Bool) in
								
								self.searchImageViewOn.alpha = 1.0
								self.searchImageCircle.alpha = 0.0
								self.searchImageCrossLeft.alpha = 0.0

								self.state = INSSearchBarState.SearchBarVisible
							})
					})
			}
		}
	}
	
	func keyboardWillShow(notification: NSNotification?)
	{
		if self.searchField.isFirstResponder()
		{
			self.window.rootViewController.view.addGestureRecognizer(self.keyboardDismissGestureRecognizer)
		}
	}
	
	func keyboardWillHide(notification: NSNotification?)
	{
		if self.searchField.isFirstResponder()
		{
			self.window.rootViewController.view.removeGestureRecognizer(self.keyboardDismissGestureRecognizer)
		}
	}

	func gestureRecognizer(gestureRecognizer: UIGestureRecognizer!, shouldReceiveTouch touch: UITouch!) -> Bool
	{
		var retVal: Bool = true
		
		if CGRectContainsPoint(self.bounds, touch.locationInView(self))
		{
			retVal = false
		}
		
		return retVal
	}
}