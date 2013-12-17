void initArray (const int& randSeed, int inputArray[3][3]) {
    for(int i=0; i<3; ++i)
        for(int j=0; j<3; ++j)
            inputArray[i][j] = i + j;
}

void initFrameLeft (const int& inputArray_0__1_, const int& sumArray_0__0_, int& sumArray_0__1_) {
    sumArray_0__1_ = inputArray_0__1_ + sumArray_0__0_;
}

void initFrameUp (const int& inputArray_2__0_, const int& sumArray_1__0_, int& sumArray_2__0_) {
    sumArray_2__0_ = inputArray_2__0_ + sumArray_1__0_;
}

void justCopy (const int& inputArray_0__0_, int& sumArray_0__0_) {
    sumArray_0__0_ = inputArray_0__0_;
}

void partSum (const int& val, const int& add0, const int& add1, const int& sub0, int& res) {
    res = val + add0 + add1 - sub0;
}
