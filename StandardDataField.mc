using Toybox.WatchUi;

module DataFieldUtils {
class StandardDataField extends WatchUi.DataField {
	var value = "";
	var label = "";

	const _value_font_smallest = Graphics.FONT_SYSTEM_NUMBER_MILD;
	const _value_font_biggest = Graphics.FONT_SYSTEM_NUMBER_THAI_HOT;
	var _value_font;
	var _label_font = Graphics.FONT_SYSTEM_TINY;
	var _value_x;
	var _value_y;
	var _label_x;
	var _label_y;
	const PAD = 3;
	const SPACING = 2;

	function initialize() {
		DataField.initialize();
	}

	function onLayout(dc) {
		System.println("onLayout " + dc.getWidth() + "x" + dc.getHeight());
		DataField.onLayout(dc);
		_value_x = dc.getWidth() / 2;
		_label_x = _value_x;
		_label_y = Graphics.getFontDescent(_label_font);
		// find the biggest possible font for the value
		var max_value_height = dc.getHeight() - Graphics.getFontHeight(_label_font) - PAD - SPACING;

		System.println("max_value_height " + max_value_height);
		_value_font = _value_font_smallest;
		var bigger;
		for (bigger = 0; bigger < _value_font_biggest - _value_font_smallest; bigger ++) {
			System.println("fontheight " + bigger + ": " + Graphics.getFontHeight(_value_font + bigger));
			if (!(Graphics.getFontHeight(_value_font + bigger) < max_value_height)) {
				break;
			}
		}
		System.println("increasing value font by " + bigger);
		_value_font += bigger;

		_value_y = dc.getHeight() - Graphics.getFontAscent(_value_font) - PAD
			- (max_value_height - Graphics.getFontHeight(_value_font)) / 2; // shift up to center in free space
		return true;
	}

	function onUpdate(dc) {
		System.println("onUpdate " + dc.getWidth() + "x" + dc.getHeight());
		var bgc = getBackgroundColor();
		var fgc = Graphics.COLOR_BLACK;
		if (bgc == Graphics.COLOR_BLACK) {
			fgc = Graphics.COLOR_WHITE;
		}
		dc.setColor(fgc, bgc);

		dc.clear();
		dc.drawText(_value_x, _value_y, _value_font, value, Graphics.TEXT_JUSTIFY_CENTER);
		dc.drawText(_label_x, _label_y, _label_font, label, Graphics.TEXT_JUSTIFY_CENTER);

		return true;
	}

}
}