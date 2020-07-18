using Toybox.WatchUi;
using Toybox.System;

module DataFieldUtils {
class StandardDataField extends WatchUi.DataField {
	var value = "";
	var label = "";
	var _ref_value = "000";		// reference for value width

	const _value_font_smallest = Graphics.FONT_SYSTEM_NUMBER_MILD;
	const _value_font_biggest = Graphics.FONT_SYSTEM_NUMBER_THAI_HOT;
	var _value_font;
	var _label_font = Graphics.FONT_SYSTEM_TINY;
	var _value_x;
	var _value_y;
	var _label_x;
	var _label_y;

	function initialize() {
		DataField.initialize();
	}

	function onLayout(dc) {
		var PAD;
		var SPACING;
		var PADDING;
		if (System.getDeviceSettings().screenShape == System.SCREEN_SHAPE_ROUND) {
			PAD = 5;
			SPACING = -23;
			PADDING = 12;
		} else {
			PAD = -5;
			SPACING = -7;
			PADDING = 40;
		}
		System.println("onLayout " + dc.getWidth() + "x" + dc.getHeight());
		DataField.onLayout(dc);
		_value_x = dc.getWidth() / 2;
		_label_x = _value_x;
		_label_y = Graphics.getFontDescent(_label_font);
		// find the biggest possible font for the value
		var label_font_height = Graphics.getFontHeight(_label_font);
		var max_value_height = dc.getHeight() - label_font_height - PAD - SPACING;

		System.println("max_value_height " + max_value_height + " label font height " + label_font_height);
		_value_font = _value_font_smallest;
		var bigger;
		for (bigger = 0; bigger < _value_font_biggest - _value_font_smallest; bigger ++) {
			var fh = Graphics.getFontHeight(_value_font + bigger);
			var fw = dc.getTextWidthInPixels(_ref_value, _value_font + bigger);
			System.println("fontheight " + bigger + ": " + fh);
			System.println("fontwidth " + bigger + ": " + fw);
			if ((fh > max_value_height) || (fw + PADDING > dc.getWidth())) {
				break;
			}
		}
		if (bigger > 0) {		// breaks when too big
			bigger --;
		}
		System.println("increasing value font by " + bigger + " height " + Graphics.getFontHeight(_value_font));
		_value_font += bigger;

		_value_y = dc.getHeight() - Graphics.getFontAscent(_value_font) - PAD;
		System.println("value y " + _value_y);
		if (max_value_height > Graphics.getFontHeight(_value_font) + 3) {
			_value_y -= (max_value_height - Graphics.getFontHeight(_value_font)) / 2; // shift up to center in free space
			System.println("centering value y to " + _value_y);
		}
		return true;
	}

	function onUpdate(dc) {
		var bgc = getBackgroundColor();
		var fgc = Graphics.COLOR_BLACK;
		if (bgc == Graphics.COLOR_BLACK) {
			fgc = Graphics.COLOR_WHITE;
		}
		dc.setColor(fgc, bgc);
		dc.clear();

		dc.setColor(fgc, Graphics.COLOR_TRANSPARENT);
		dc.drawText(_value_x, _value_y, _value_font, value, Graphics.TEXT_JUSTIFY_CENTER);
		dc.drawText(_label_x, _label_y, _label_font, label, Graphics.TEXT_JUSTIFY_CENTER);

		return true;
	}

}
}