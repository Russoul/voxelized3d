module traits;

import util;

T zero(T)(){ //TODO do it in an extensive way
	static if (is (T == int)) return 0;
	static if (is (T == float)) return 0.0f;
	static if (is (T == double)) return 0.0;
	static if (is (T == size_t)) return 0;
}

