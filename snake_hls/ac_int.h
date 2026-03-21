// ac_int.h — minimal stub for testing the __SYNTHESIS__ compile path
// Mimics Catapult ac_int<W,S> just enough to compile snake.cpp.
// NOT for synthesis. Use with:
//   g++ -D__SYNTHESIS__ -c snake.cpp -I.
//
// Key design decisions to avoid g++ ambiguity errors:
//   - Single constructor from long long  (int/unsigned promote to long long automatically)
//   - Template copy constructor for ac_int<W2,S2> → ac_int<W,S>  (resolves cross-width casts)
//   - Single implicit conversion: operator long long()  (no competing operator int() etc.)

#ifndef AC_INT_H
#define AC_INT_H

template<int W, bool Signed>
class ac_int {
    long long val;

    long long mask() const {
        if (W >= 64) return val;
        long long m = (1LL << W) - 1LL;
        return Signed ? val : (val & m);
    }

public:
    // --- Constructors ---

    ac_int() : val(0) {}

    // Single numeric constructor — int/unsigned int/etc. all promote to long long
    ac_int(long long v) : val(v) {}

    // Template copy constructor — handles ac_int<W2,S2> → ac_int<W,S> casts
    template<int W2, bool S2>
    ac_int(const ac_int<W2,S2>& o) : val((long long)o) {}

    // --- Single implicit conversion ---
    // One operator avoids ambiguity on array indexing and arithmetic.
    // long long is accepted by array subscript, comparisons, and arithmetic.
    operator long long() const { return mask(); }

    // --- Arithmetic ---
    ac_int operator+(const ac_int& o) const { return ac_int(val + o.val); }
    ac_int operator-(const ac_int& o) const { return ac_int(val - o.val); }
    ac_int operator-()                const { return ac_int(-val); }
    ac_int operator*(const ac_int& o) const { return ac_int(val * o.val); }

    // int overloads — exact match for "ac_int op int_literal" expressions
    // (e.g. st.length - 1) preventing ambiguity between the member operator
    // and the built-in operator-(long long, int) via operator long long().
    ac_int operator+(int n) const { return ac_int(val + n); }
    ac_int operator-(int n) const { return ac_int(val - n); }

    ac_int& operator+=(const ac_int& o) { val += o.val; return *this; }
    ac_int& operator-=(const ac_int& o) { val -= o.val; return *this; }

    // --- Bitwise ---
    ac_int operator>>(int n) const { return ac_int(val >> n); }
    ac_int operator<<(int n) const { return ac_int(val << n); }
    ac_int operator|(const ac_int& o) const { return ac_int(val | o.val); }
    ac_int operator&(const ac_int& o) const { return ac_int(val & o.val); }
    ac_int operator^(const ac_int& o) const { return ac_int(val ^ o.val); }

    // --- Comparison ---
    bool operator==(const ac_int& o) const { return mask() == o.mask(); }
    bool operator!=(const ac_int& o) const { return mask() != o.mask(); }
    bool operator< (const ac_int& o) const { return mask() <  o.mask(); }
    bool operator> (const ac_int& o) const { return mask() >  o.mask(); }
    bool operator<=(const ac_int& o) const { return mask() <= o.mask(); }
    bool operator>=(const ac_int& o) const { return mask() >= o.mask(); }

    // --- Bit access ---
    bool operator[](int i) const { return (mask() >> i) & 1; }

    // --- slc<WW>(i): extract WW bits starting at bit i ---
    template<int WW>
    ac_int<WW, false> slc(int i) const {
        long long m = (WW >= 64) ? -1LL : ((1LL << WW) - 1LL);
        return ac_int<WW, false>((val >> i) & m);
    }
};

#endif // AC_INT_H
