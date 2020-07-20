//using Toybox.WatchUi;
using Toybox.Graphics;

module DataFieldUtils {
(:graph)
module Graph {
class GraphDataField extends Base.StandardDataField {
	// internal
	hidden var _hist;
	hidden var _histlen;
	hidden var _y_scale;
	hidden var _x_scale;
	hidden var _graphbuffer;
	hidden var _tick;

	// settings
	var _y_min;
	var _y_max;
	var _y_thresh;
	var _colors = { :dark => null, :bright => null};
	var _scale_x;
	var _demo = false;	// show demo values
	var _timing = false; 	// show draw timing

	// status
	var _alive;
	var _demo_val;

	function initialize() {
		StandardDataField.initialize();
		_alive = false;
		_graphbuffer = null;
		fetchSettings();
		_demo_val = _y_min;
		if (_histlen == null) {
			_histlen = System.getDeviceSettings().screenWidth;
		}
		System.println("GraphDataField init with " + _histlen);
		_hist = new RingFifo(_histlen, -_y_min);	// we use a fixed offset
		_tick = 0;
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
		if (_demo) {
			val = _demo_val;
			_demo_val += (_y_max - _y_min) / 100 +1;
			if (_demo_val > _y_max + 50) {
				_demo_val = _y_min;
			}
		}

		// just do nothing if we never get a value
		if (val != 0) {
			_alive = true;
		}
		if (!_alive) {
			return;
		}
		// scaling must be done at each update, because the layout can change anytime
		_hist.push_pop(val - _y_min);	// calculate offset here: only once per value
		_tick++;
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
		var yg;
		var y;
		var x;

		var cmode;
		if (fgc == Graphics.COLOR_WHITE) {
			cmode = :dark;
		} else {
			cmode = :bright;
		}
		var colors = _colors[cmode];
		var bgc = colors[0];

		var xg;
		if (_graphbuffer == null ||
				_graphbuffer.getCmode() != cmode ||
				_graphbuffer.getHeight() != dc.getHeight()) {
			_graphbuffer = new GraphBuffer(dc.getWidth(), dc.getHeight(), _tick, _colors, cmode);
			xg = 0;
			System.println("new bitmap");
		} else {
			xg = _graphbuffer.shift(_tick);
//			System.println("shift bitmap " + xg);
		}

		var dcbm = _graphbuffer.getDc();
		var h = dcbm.getHeight();
		var w = dcbm.getWidth();
		var histoffs = _histlen - w ;
		dcbm.setPenWidth(1);

		for (; xg < w; xg+= 1) {
			if (_scale_x) {			// scale to fit field size
				y = interp(xg);
			} else if (histoffs + xg < 0 ) {	// pad with empty space if history is too short
				y = 0;
			} else {		// one pixel per history record
				y = _hist.at(histoffs + xg);	// skip to history start
			}

			yg = scaley(y);
			if (y <= 0) { // below thresh
				continue;
			}
			if (y < _y_thresh) {
				dcbm.setColor(colors[1], bgc);
			} else if (y < _y_max - _y_min) {
				dcbm.setColor(colors[2], bgc);
			} else {
				dcbm.setColor(colors[3], bgc);
				yg = h;
			}
			dcbm.drawLine(xg, h, xg, h-yg);
		}
		dc.drawBitmap(dc.getWidth() - w, 0, _graphbuffer);	// allow for a wider buffer than the field
		var clock = System.getTimer() - start;
		// takes about 250ms on the Edge 820!
		if(_timing) {
			label = clock;
		}
	}

	function drawText(dc, fgc) {
		if (_demo) {
			value = _demo_val;
		}

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

	// Get a color code number from a hex string setting.
	// Return the defaultValue on invalid inputs.
	function getColorSetting(name, defaultValue) {
		var v = Application.Properties.getValue(name).toNumberWithBase(16);
		if (v == null) {
			return defaultValue;
		}
		return v;
	}

}

class GraphBuffer extends Graphics.BufferedBitmap {
	var _t;
	var _w;
	var _h;
	var _tscale;
	var _fgc;
	var _bgc;
	var _cmode;
	function initialize(w, h, t, colors, cmode) {
		BufferedBitmap.initialize({:width => w, :height => h, :palette => colors[cmode]});
		_t = t;
		_w = w;
		_h = h;
		_cmode = cmode;
		_tscale = 1;
		getDc().clear();
	}

	function shift(now) {
		var dc = getDc();
		var s = (_t - now) * _tscale;
		dc.setColor(getPalette()[0], getPalette()[0]);
		if (s <= -_w) {	// no useful content left, need a full redraw
			System.println("bitmap expired");
			dc.clear();
			_t = now;
			return 0;
		}
		dc.drawBitmap(s, 0, self);
		dc.fillRectangle(_w + s, 0, -s, _h);
		_t = now;
		return _w + s;
	}

	function getCmode() {
		return _cmode;
	}

	function getWidth() {
		return _w;
	}
	function getHeight() {
		return _h;
	}

}
}
}