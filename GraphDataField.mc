//using Toybox.WatchUi;
using Toybox.Graphics;

module DataFieldUtils {
class GraphDataField extends StandardDataField {
	var _hist;
	var _histlen;
	hidden var _y_scale;
//	hidden var _y_off;
	hidden var _x_scale;

	hidden var _y_min;
	hidden var _y_max;
	hidden var _y_thresh;
	hidden var _color_lo;
	hidden var _color_hi;
	hidden var _color_ov;

	var _alive;


	function initialize() {
		StandardDataField.initialize();
		_alive = false;
		_histlen = 300;
		_y_min = 100;
		_y_max = 500;
		_y_thresh = 300 - _y_min;
		_color_lo = Graphics.COLOR_BLUE;
		_color_hi = Graphics.COLOR_ORANGE;
		_color_ov = Graphics.COLOR_RED;

		fetchSettings();

		_hist = new RingFifo(_histlen, 0);
	}

	function onLayout(dc) {
		StandardDataField.onLayout(dc);
		var w = dc.getWidth();
		var h = dc.getHeight();
		_y_scale = (_y_max - _y_min).toFloat() / h;
		_x_scale = _histlen.toFloat() / w;
	}

	function fetchSettings() {
		// override this!
		System.println("WARNING: base class fetchSettings called, override it?");
	}

	function pushGraph(val) {
		// just do nothing if we never get a value
		if (val != 0) {
			_alive = true;
		}
		if (val == 0 && !_alive) {
			return;
		}
		// scaling must be done at each update, because the layout can change anytime
		_hist.push_pop(val - _y_min);	// calculate offset here: only once per value
	}

	function onUpdate(dc) {
		var bgc = getBackgroundColor();
		var fgc = Graphics.COLOR_BLACK;
		if (bgc == Graphics.COLOR_BLACK) {
			fgc = Graphics.COLOR_WHITE;
		}

		dc.setColor(fgc, bgc);
		dc.clear();

		if (_alive) {
			drawGraph(dc, fgc);
		}
		drawText(dc, fgc);

		return true;
	}

	function drawGraph(dc, fgc) {
		var h = dc.getHeight();
		var w = dc.getWidth();
		var yg;
		var y;
		var x;

		var bgc = Graphics.COLOR_TRANSPARENT;
		for (var xg = 0; xg < w; xg++) {
			x = scalexg(xg);
			y = _hist.at(x);
			yg = scaley(y);
			if (y <= 0) { // below thresh
				continue;
			}
			if (y < _y_thresh) {
				dc.setColor(_color_lo, bgc);
			} else if (y < _y_max) {
				dc.setColor(_color_hi, bgc);
			} else {
				dc.setColor(_color_ov, bgc);
				yg = h;
			}
			dc.drawLine(xg, h, xg, h-yg);
		}
	}

	function drawText(dc, fgc) {
		var bgc = Graphics.COLOR_TRANSPARENT;

		dc.setColor(Graphics.COLOR_LT_GRAY, bgc);
		dc.drawText(_label_x, _label_y, _label_font, label, Graphics.TEXT_JUSTIFY_CENTER);
		dc.setColor(fgc, bgc);
		dc.drawText(_value_x, _value_y, _value_font, value, Graphics.TEXT_JUSTIFY_CENTER);
	}

	function scalexg(xg) {
		return (xg * _x_scale).toNumber();
	}

	function scaley(y) {
		return y / _y_scale;
	}


}
}