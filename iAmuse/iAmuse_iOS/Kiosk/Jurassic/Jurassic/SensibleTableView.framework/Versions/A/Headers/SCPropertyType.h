/*
 *  SCPropertyType.h
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


/** @enum The types of an SCPropertyDefinition */
typedef enum
{
	/** The object bound to the property will detect the best user interface element to generate. */
	SCPropertyTypeAutoDetect=0,
	/**	The object bound to the property will generate an SCLabelCell interface element */
	SCPropertyTypeLabel,
	/**	The object bound to the property will generate an SCTextViewCell interface element */
	SCPropertyTypeTextView,
	/**	The object bound to the property will generate an SCTextFieldCell interface element */
	SCPropertyTypeTextField,
	/**	The object bound to the property will generate an SCNumericTextFieldCell interface element */
	SCPropertyTypeNumericTextField,
	/**	The object bound to the property will generate an SCSliderCell interface element */
	SCPropertyTypeSlider,
	/**	The object bound to the property will generate an SCSegmentedCell interface element */
	SCPropertyTypeSegmented,
	/**	The object bound to the property will generate an SCSwitchCell interface element */
	SCPropertyTypeSwitch,
	/**	The object bound to the property will generate an SCDateCell interface element */
	SCPropertyTypeDate,
	/**	The object bound to the property will generate an SCImagePickerCell interface element */
	SCPropertyTypeImagePicker,
	/**	The object bound to the property will generate an SCSelectionCell interface element */
	SCPropertyTypeSelection,
	/**	The object bound to the property will generate an SCObjectSelectionCell interface element */
	SCPropertyTypeObjectSelection,
	/**	The object bound to the property will generate an SCObjectCell interface element */
	SCPropertyTypeObject,
	/**	The object bound to the property will generate an SCArrayOfObjectsCell interface element */
	SCPropertyTypeArrayOfObjects,
	/**	The object bound to the property will generate a custom interface element */
	SCPropertyTypeCustom,
	/**	The object bound to the property will not generate an interface element */
	SCPropertyTypeNone,
	/**	Undefined property type */
	SCPropertyTypeUndefined
	
} SCPropertyType;

