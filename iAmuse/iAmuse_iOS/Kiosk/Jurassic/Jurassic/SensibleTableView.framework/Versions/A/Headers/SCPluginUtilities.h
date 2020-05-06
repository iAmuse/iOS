/*
 *  SCPluginUtilities.h
 *  Sensible TableView
 *  Version: 3.4.0
 *
 *
 *	THIS SOURCE CODE AND ANY ACCOMPANYING DOCUMENTATION ARE PROTECTED BY UNITED STATES
 *	INTELLECTUAL PROPERTY LAW AND INTERNATIONAL TREATIES. UNAUTHORIZED REPRODUCTION OR
 *	DISTRIBUTION IS SUBJECT TO CIVIL AND CRIMINAL PENALTIES. YOU SHALL NOT DEVELOP NOR
 *	MAKE AVAILABLE ANY WORK THAT COMPETES WITH A SENSIBLE COCOA PRODUCT DERIVED FROM THIS
 *	SOURCE CODE. THIS SOURCE CODE MAY NOT BE RESOLD OR REDISTRIBUTED ON A STAND ALONE BASIS.
 *
 *	USAGE OF THIS SOURCE CODE IS BOUND BY THE LICENSE AGREEMENT PROVIDED WITH THE
 *	DOWNLOADED PRODUCT.
 *
 *  Copyright 2012-2013 Sensible Cocoa. All rights reserved.
 *
 *
 *	This notice may not be removed from this file.
 *
 */


#define kCustomClassName                @"_STV_CustomClassName"
#define kibUniqueID                     @"ibUniqueID"
#define kSectionIndexKey                @"index"
#define kSectionTypeKey                 @"type"
#define kSectionDataDefIdKey            @"dataDefinitionID"
#define kSectionPlaceholderTextKey      @"placeholderText"
#define kSectionAddNewItemTextKey       @"addNewItemText"
#define kDefaultDataDefinitionName      @"(none selected)"
#define kPropertyGroups                 @"propertyGroups"
#define kPropertyDefinitions            @"propertyDefinitions"


/* This class is used internally to provide STV plugin-related utilities */


@interface SCPluginUtilities : NSObject

+ (id)objectForPluginDictionary:(NSDictionary *)pluginDictionary;

@end


@protocol SCibInitialization <NSObject>

- (id)initWithibDictionary:(NSMutableDictionary *)ibDictionary;

@end