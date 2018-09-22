module DataFieldUtils {
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
		_fifo = new [_N];
		reset(val);
	}

	function reset(val) {
		if (_N == 1) {
			return;
		}
		for(var i = 0; i < _N; i++) {
		  _fifo[i] = val;
  		}
  		// initialize the accumulator
  		_y = _N * val;
	}

	function push_back(x) {
		if (_N == 1)  {
			return x * _gain;
		}
    	_y += x - _fifo[0];
	   for (var i = 0; i < _N - 1; i++) {
    	_fifo[i] = _fifo[i+1];
    	}
    	_fifo[_N - 1] = x;
    	return _y * _gain;
	}

}
}