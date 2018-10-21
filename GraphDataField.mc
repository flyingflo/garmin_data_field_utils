//using Toybox.WatchUi;
using Toybox.Graphics;

module DataFieldUtils {
class GraphDataField extends StandardDataField {
	// internal
	hidden var _hist;
	hidden var _histlen;
	hidden var _y_scale;
	hidden var _x_scale;

	// settings
	var _y_min;
	var _y_max;
	var _y_thresh;
	var _colors_dark;
	var _colors_bright;
	var _scale_x;

	// status
	var _alive;
	var _lcol; 	//cached graph line color to reduce setColor calls

	function initialize() {
		StandardDataField.initialize();
		_alive = false;
//		_histlen = 210;
//		_y_min = 100;
//		_y_max = 500;
//		_y_thresh = 300 - _y_min;
//		_color_lo = Graphics.COLOR_GREEN;
//		_color_hi = Graphics.COLOR_BLUE;
//		_color_ov = Graphics.COLOR_RED;
//		_scale_x = false;
//
		fetchSettings();
		if (_histlen == null) {
			_histlen = System.getDeviceSettings().screenWidth;
		}
		System.println("GraphDataField init with " + _histlen);
		_hist = new RingFifo(_histlen, -_y_min);	// we use a fixed offset
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

	function gethist(i) {
		// because we save values with an offset, we have to fix this for callers
		return _hist.at(i) + _y_min;
	}

	function gethistlen() {
		return _histlen;
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

        // Call parent's onUpdate(dc) to redraw the layout
//        View.onUpdate(dc);
		return true;
	}

	function drawGraph(dc, fgc) {
		var start = System.getTimer();
		var h = dc.getHeight();
		var w = dc.getWidth();
		var yg;
		var y;
		var x;
		var histoffs = _histlen - w ;

		var colors;
		if (fgc == Graphics.COLOR_WHITE) {
			colors = _colors_dark;
		} else {
			colors = _colors_bright;
		}
		var bgc = colors[0];
//		var bm = new Graphics.BufferedBitmap({:width => w, :height => h, :palette => colors});
		dc.setColor(bgc, bgc);
		dc.clear();
		var dcbm = dc; //bm.getDc();
		dcbm.setPenWidth(1);

		_lcol = bgc;
		var lcolnext;

		for (var xg = 0; xg < w; xg+= 1) {
			if (_scale_x) {			// scale to fit field size
				y = interp(xg);
			} else if (histoffs + xg < 0 ) {	// one pixel per history record
				y = 0;
			} else {		// pad with empty space if history is too short
				y = _hist.at(histoffs + xg);	// skip to history start
			}
			yg = scaley(y);
			if (y <= 0) { // below thresh
				continue;
			}
			if (y < _y_thresh) {
				lcolnext = colors[1];
			} else if (y < _y_max) {
				lcolnext = colors[2];
			} else {
				lcolnext = colors[3];
				yg = h;
			}
			setColorCached(dcbm, lcolnext, bgc);
			dcbm.drawLine(xg, h, xg, h-yg);
		}
		var clock = System.getTimer() - start;
//		dc.drawBitmap(0,0, bm);
		// takes about 250ms on the Edge 820!
//		value = clock;
	}
	function setColorCached(dc, fc, bc) {
		if (fc == _lcol) {
			return;
		}
		dc.setColor(fc, bc);
		_lcol = fc;
	}

	function drawText(dc, fgc) {
		var bgc = Graphics.COLOR_TRANSPARENT;

		dc.setColor(Graphics.COLOR_LT_GRAY, bgc);
		dc.drawText(_label_x, _label_y, _label_font, label, Graphics.TEXT_JUSTIFY_CENTER);
		dc.setColor(fgc, bgc);
		dc.drawText(_value_x, _value_y, _value_font, value, Graphics.TEXT_JUSTIFY_CENTER);
	}

	function interp(xg) {
		var x = (xg * _x_scale);
		var x0 = x.toNumber();
		var x1 = x0 + 1;
		var y0 = _hist.at(x0);
		var y1 = _hist.at(x1);
//		return y0 * (x1 - x) + y1 * (x - x0);	// linear interpolation
		if (y0 > y1) {		// deliver maximum
			return y0;
		} else {
			return y1;
		}
	}

	function scaley(y) {
		return (y / _y_scale).toNumber();
	}


}
}