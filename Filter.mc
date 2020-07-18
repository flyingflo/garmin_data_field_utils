using Toybox.Test;

module DataFieldUtils {
(:filter)
class AvgFilter {
	/* Recursive moving average filter.
	*/
	hidden var _N;
	hidden var _fifo;
	hidden var _gain;
	hidden var _y;
	function initialize(len, val, gain) {
		_N = len;
		_gain = gain;
		if (_N == 1) {
			return;
		}
		_fifo = new RingFifo(_N, val);
  		// initialize the accumulator
  		_y = _N * val;
	}

	function reset(val) {
		if (_N == 1) {
			return;
		}
		_fifo.reset(val);
  		// initialize the accumulator
  		_y = _N * val;
	}

	function push_back(x) {
		if (_N == 1)  {
			return x * _gain;
		}
    	_y += x - _fifo.push_pop(x);
    	return _y * _gain;
	}

}

(:test)
function filtertest(logger) {
	var f = new AvgFilter(5, 0, 1);
	for (var x = 0; x < 5; x++) {
		var v = f.push_back(5);
		logger.debug(v);
		Test.assert(v == (x+1) * 5);
	}
	for (var x = 0; x < 5; x++) {
		var v = f.push_back(5);
		logger.debug(v);
		Test.assert(v == 5 * 5);
	}
	return true;
}
}