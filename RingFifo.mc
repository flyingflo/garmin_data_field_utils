using Toybox.Test;

module DataFieldUtils {

class RingFifo {

	hidden var _buf;
	hidden var _len;
	hidden var _i;

	function initialize(len, val) {
		_buf = new[len];
		_len = len;
		_i = 0;
		for (var i = 0; i < _len; i++) {
			_buf[i] = val;
		}
	}

	hidden function wrap_index(i) {
		while (i < 0) {
			i += _len;
		}
		while (i >= _len) {
			i -= _len;
		}
		return i;
	}

	function push_pop(val) {
		var pop = _buf[_i];
		_buf[_i] = val;
		_i = wrap_index(_i + 1);
		return pop;
	}

	function at(i) {
		return _buf[wrap_index(i + _i)];
	}
}

(:test)
function testfill(logger) {
	logger.debug("testfill");
	var len = 300;
	var hist = new RingFifo(len, 42);
	for (var i = 0; i < len; i++) {
		if (hist.at(i) != 42) {
			logger.error("init failed " + hist.at(i));
			return false;
		}
	}
	return true;
}

(:test)
function testat(logger) {
	logger.debug("testat");
	var len = 300;
	var hist = new RingFifo(len, 42);
	for (var i = 0; i < len; i++) {
		var r = hist.push_pop(i);
		Test.assertEqual(r, 42);
		if (hist.at(-1) != i) {
			logger.error("push failed " + hist.at(-1));
			return false;
		}
	}
	for (var i = 0; i < len * 5; i++) {
		Test.assertEqual(hist.at(i), i % len);
	}
	for (var i = 0; i < -(len * 5); i--) {
		Test.assertEqual(hist.at(i), (len-i) % len);
	}
	return true;
}

}