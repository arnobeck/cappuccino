/*
 * CPClipView.j
 * AppKit
 *
 * Created by Francisco Tolmasky.
 * Copyright 2008, 280 North, Inc.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */

import "CPView.j"

#include "CoreGraphics/CGGeometry.h"

/*
    <objj>CPClipView</objj> allows you to define a clip rect and display only that portion of its containing view.  
    It is used to hold the document view in a <objj>CPScrollView</objj>.
*/
@implementation CPClipView : CPView
{
    CPView  _documentView;
}

/*
    Sets the document view to be <code>aView</code>.
    @param aView the new document view. It's frame origin will be changed to <code>(0,0)</code> after calling this method.
*/
- (void)setDocumentView:(CPView)aView
{
    if (_documentView == aView)
        return;

    var defaultCenter = [CPNotificationCenter defaultCenter];
    
    if (_documentView)
    {
        [defaultCenter
            removeObserver:self
                      name:CPViewFrameDidChangeNotification
                    object:_documentView];

        [defaultCenter
            removeObserver:self
                      name:CPViewBoundsDidChangeNotification
                    object:_documentView];
        
        [_documentView removeFromSuperview];
    }
    
    _documentView = aView;
    
    if (_documentView)
    {
        // FIXME: remove when bounds.
        [_documentView setFrameOrigin:CGPointMake(0.0, 0.0)];
            
        [self addSubview:_documentView];
        
		[_documentView setPostsFrameChangedNotifications:YES];
		[_documentView setPostsBoundsChangedNotifications:YES];

		[defaultCenter
            addObserver:self
               selector:@selector(viewFrameChanged:)
                   name:CPViewFrameDidChangeNotification 
                 object:_documentView];

		[defaultCenter
            addObserver:self
               selector:@selector(viewBoundsChanged:)
                   name:CPViewBoundsDidChangeNotification 
                 object:_documentView];
    }
}

/*
    Returns the document view.
*/
- (id)documentView
{
    return _documentView;
}

/*
    Returns a new point that may be adjusted from <code>aPoint</code>
    to make sure it lies within the document view.
    @param aPoint
    @return the adjusted point
*/
- (CGPoint)constrainScrollPoint:(CGPoint)aPoint
{
    var documentFrame = [_documentView frame];
    
    aPoint.x = MAX(0.0, MIN(aPoint.x, MAX(_CGRectGetWidth(documentFrame) - _CGRectGetWidth(_bounds), 0.0)));
    aPoint.y = MAX(0.0, MIN(aPoint.y, MAX(_CGRectGetHeight(documentFrame) - _CGRectGetHeight(_bounds), 0.0)));

    return aPoint;
}

- (void)setBoundsOrigin:(CGPoint)aPoint
{
    if (_CGPointEqualToPoint(_bounds.origin, aPoint))
        return;
        
    [super setBoundsOrigin:aPoint];

    var superview = [self superview];
    
    if([superview isKindOfClass:[CPScrollView class]])
        [superview reflectScrolledClipView:self];
}

/*
    Scrolls the clip view to the specified point. The method
    sets its bounds origin to <code>aPoint</code>.
*/
- (void)scrollToPoint:(CGPoint)aPoint
{
    [self setBoundsOrigin:[self constrainScrollPoint:aPoint]];
}

/*
    Handles a <objj>CPViewBoundsDidChangeNotification</objj>.
    @param aNotification the notification event
*/
- (void)viewBoundsChanged:(CPNotification)aNotification
{
    var superview = [self superview];
    
    if([superview isKindOfClass:[CPScrollView class]])
        [superview reflectScrolledClipView:self];
}

/*
    Handles a <objj>CPViewFrameDidChangeNotification</objj>.
    @param aNotification the notification event
*/
- (void)viewFrameChanged:(CPNotification)aNotification
{
    var superview = [self superview];

    if([superview isKindOfClass:[CPScrollView class]])
        [superview reflectScrolledClipView:self];
}

@end
