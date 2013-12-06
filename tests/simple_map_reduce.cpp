#include <cstdlib>
#include <cmath>

void fillArray (const int& randSeed, double inArray[10]) {
    srand(randSeed);
    for(int i = 0; i < randSeed; ++i)
        inArray[i] = rand() % 100;
}

void squareRoot (const double& in, double& out) {
    out = sqrt(in);
}

void sumArray (double outArray[10], double& sum) {
    sum = 0;
    for (int i = 0; i < 10; ++i) sum += outArray[i];
}
