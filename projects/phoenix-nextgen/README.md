## Data Sources##

Home prices came from Zillow's Home Value Index. Go to https://www.zillow.com/research/data/ ,
and download all homes by ZIP code.

---

# Results

All estimates use log home value as the outcome, with zip code and month fixed
effects, standard errors clustered by zip code. Panel: 147 zip codes in Maricopa
and Pinal County, monthly, January 2010 – January 2020 (17,749 observations).

---

## Table 1. Did affected areas grow more slowly?

Annual growth rate relative to control zip codes.

| Group             | Sept 2014 – Aug 2017 | After Aug 2017 |
|---                |---                   |---             |
| Newly affected    | +0.2%                | −2.8%          |
| Lost noise        | +3.9%                | −4.0%          |
| Always affected   | +4.2%                | −3.1%          |

The first column covers the period when NextGen was in
effect. The second covers the period after the court ordered it reversed. A
negative number means that group's home values grew more slowly than the
control group's over that stretch.

The newly-affected group (the one that gained flight noise) shows no
difference at all while the planes were overhead. All three groups decline at
similar rates afterward, including the always-affected group, whose exposure
never changed at either date.

---

## Table 2. Main specification

Monthly differential trend, log points.

|                         | Newly affected | Lost noise     | Always affected |
|---                      |---             |---             |---              |
| Post-shock trend        | 0.00020        | 0.00328        | 0.00345\*\*\*   |
|                         | (0.00171)      | (0.00182)      | (0.00123)       |
| Change after reversal   | −0.00255       | −0.00658\*\*\* | −0.00603\*\*\*  |
|                         | (0.00195)      | (0.00206)      | (0.00149)       |
| Net post-reversal trend | −0.00235\*\*\* | −0.00330\*\*\* | −0.00258\*\*\*  |
|                         | (0.00064)      | (0.00057)      | (0.00054)       |

Standard errors in parentheses. \*\*\* p<0.01, \*\* p<0.05, \* p<0.10.
Net post-reversal trend is the sum of the two rows above it, computed with
`lincom` so the standard error accounts for covariance between the estimates.
Multiply any coefficient by 12 for an annual rate.

---

## Table 3. Is the control group a valid comparison?

| Group             | Pre-trend test (p) | Placebo shock, Sept 2012 | Verdict        |
|---                |---                 |---                       |---             |
| Newly affected    | 0.335              | +2.1%/yr (p = 0.413)     | Passes both    |
| Lost noise        | 0.018              | +7.9%/yr (p = 0.003)     | Fails both     |
| Always affected   | 0.003              | +7.9%/yr (p < 0.001)     | Fails both     |

The pre-tredn test is a joint F-test that all four pre-treatment event-study
coefficients equal zero. A high p-value is the good outcome because it means the
groups were tracking each other before anything happened.

Placebo shock applies the same model to a fake treatment date in September
2012, using pre-treatment data only. Any apparent effect is by construction
spurious. Lost-noise and always-affected both produce a large, highly
significant "effect" from a policy that never happened, roughly twice the size
of their coefficients at the real 2014 shock.

Only the newly-affected group survives both checks. The other two cannot be
compared against control.

---

## Table 4. The cleanest comparison: lost noise vs always affected

Both groups sat under the same pre-2014 flight corridor, the same neighbourhoods,
and the same submarket. After NextGen, one lost its overflights and the other kept them.

|                       | Coefficient | Std. err. | p     |
|---                    |---          |---        |---    |
| Post-shock trend      | −0.00017    | 0.00168   | 0.918 |
| Change after reversal | −0.00054    | 0.00174   | 0.755 |

96 zip codes, 11,616 observations.

This comparison holds geography constant, so it isolates the effect of noise in
a way that no comparison against the suburban control group can. The two groups
are statistically indistinguishable in both periods.

---

## Table 5. Event study - newly affected vs control

Cumulative gap relative to the year before the shock, log points.

| Years from Sept 2014 | Coefficient | Std. err.|
|---                   |---          |---       |
| −5                   | −0.043      | 0.042    |
| −4                   | −0.044      | 0.046    |
| −3                   | −0.019      | 0.039    |
| −2                   | −0.008      | 0.016    |
| −1                   | baseline    | —--      |
| 0                    | −0.000      | 0.011    |
| +1                   | −0.010      | 0.023    |
| +2                   | −0.012      | 0.034    |
| +3                   | −0.032      | 0.042    |
| +4                   | −0.058      | 0.045    |
| +5                   | −0.070      | 0.049    |

No coefficient is statistically distinguishable from zero. The pre-treatment
values are flat, which is what validates the design. The gap opens only from
year +3 onward (from 2017) which coincides with the court-ordered
reversal rather than with the 2014 rerouting.

---

## Headline estimate

Cumulative gap for newly-affected zip codes by January 2020:

**−6.3%** (95% CI: −18.0% to +5.3%, p = 0.284)

The point estimate is negative but cannot be distinguished from zero, and the
interval is wide enough to contain effects of the size the hedonic noise
literature reports (roughly 0.5–1.0% of home value per decibel). This is a
null result driven by limited precision, not evidence that no effect exists.

---

## What the tables show together

Two independent routes reach the same answer.

Comparing newly-affected zips against control (the one comparison that
survives both validity checks) finds no detectable effect, and what movement
there is arrives three years after the planes did.

Comparing lost-noise against always-affected (the comparison that holds
neighbourhood and submarket constant) finds nothing in either period.

The large, significant effects produced by the original specification
(+$18,486 per home, p = 0.004) do not survive logging the outcome, adding month
fixed effects, or a placebo test.