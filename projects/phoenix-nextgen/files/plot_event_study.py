"""
plot_event_study.py
===================

Redraws the event-study chart from Table 5 of the Phoenix Sky Harbor NextGen
analysis, styled to match the portfolio site.

WHAT THIS DOES NOT DO: it does not re-run the regression. The coefficients and
standard errors below are the output of the Stata model (see revised_annotated.do).
This script only handles the *rendering* — it takes numbers that already exist
and draws them in the site's colours and fonts instead of Stata's defaults.

Run it with:      python3 plot_event_study.py
Output:           event_study_hero.svg  (written next to this script)

SVG rather than PNG because it stays sharp at any size and the file is tiny —
both of which matter for an image sitting at the top of a web page.
"""

import matplotlib

# Use the "Agg" backend. A backend is the thing matplotlib draws *with*; Agg
# writes straight to a file and never tries to open a window. Without this the
# script can fail on machines with no display attached.
matplotlib.use("Agg")

import matplotlib.pyplot as plt


# ---------------------------------------------------------------------------
# THE DATA
# ---------------------------------------------------------------------------
# Straight from Table 5. Years are relative to the September 2014 shock, so
# 0 is the shock year and -1 is the baseline the model measures everything
# against.
#
# Year -1 is the reference category. By construction its coefficient is exactly
# zero and it has no standard error — there is nothing to estimate, because
# every other year is expressed as a difference *from* this one. It is included
# here so the line passes through zero at the right place.

years = [-5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5]

coefficients = [
    -0.043,  # -5
    -0.044,  # -4
    -0.019,  # -3
    -0.008,  # -2
     0.000,  # -1  <- baseline, fixed at zero by construction
    -0.000,  #  0
    -0.010,  # +1
    -0.012,  # +2
    -0.032,  # +3
    -0.058,  # +4
    -0.070,  # +5
]

# Standard errors. The baseline year gets 0.0 so the confidence band pinches
# shut at that point — which is visually correct, since there is no uncertainty
# about a value that was defined to be zero.
std_errors = [
    0.042,  # -5
    0.046,  # -4
    0.039,  # -3
    0.016,  # -2
    0.000,  # -1  <- baseline, no uncertainty by construction
    0.011,  #  0
    0.023,  # +1
    0.034,  # +2
    0.042,  # +3
    0.045,  # +4
    0.049,  # +5
]


# ---------------------------------------------------------------------------
# CONFIDENCE INTERVAL
# ---------------------------------------------------------------------------
# A 95% confidence interval is the coefficient plus or minus roughly 1.96
# standard errors. In plain terms: the range of values the data can't rule out.
#
# This is the whole point of drawing the band. The line on its own slopes
# downward and looks like a finding. The band shows that zero sits inside the
# plausible range at every single point — so the apparent decline can't be
# distinguished from noise. Publishing the line without the band would overstate
# the result.

CRITICAL_VALUE = 1.96  # 1.96 standard errors ~ 95% coverage for a normal distribution

upper_bound = [c + CRITICAL_VALUE * se for c, se in zip(coefficients, std_errors)]
lower_bound = [c - CRITICAL_VALUE * se for c, se in zip(coefficients, std_errors)]


# ---------------------------------------------------------------------------
# THE SITE PALETTE
# ---------------------------------------------------------------------------
# These are copied from theme.scss. If the palette changes there, change it
# here too — the two files are not linked, so they can drift apart.

PAPER = "#eae7e1"   # page background
INK = "#2b2a28"     # body text
BRONZE = "#a8875c"  # accent
MUTED = "#7c7873"   # secondary text
RULE = "#d3cec5"    # hairline dividers


# ---------------------------------------------------------------------------
# FONTS
# ---------------------------------------------------------------------------
# The site uses EB Garamond, but matplotlib can only use fonts installed on the
# machine running this script — it can't reach the webfont the browser loads.
# So this is a fallback chain: matplotlib walks the list and uses the first one
# it actually finds. If none are present it drops to DejaVu Serif, which is
# fine — still a serif, still in keeping.
#
# If matplotlib prints a "findfont" warning when you run this, that's what it
# is telling you: the first choice wasn't available. Harmless.

plt.rcParams["font.family"] = "serif"
plt.rcParams["font.serif"] = ["EB Garamond", "Georgia", "DejaVu Serif"]
plt.rcParams["font.size"] = 11
plt.rcParams["text.color"] = INK


# ---------------------------------------------------------------------------
# BUILD THE FIGURE
# ---------------------------------------------------------------------------
# figsize is in inches, and the ratio is what matters more than the absolute
# numbers — SVG scales cleanly either way. 11x3.8 is deliberately wide and
# short: this sits full-width under the hero, and a tall chart there would push
# everything else off the screen.

fig, ax = plt.subplots(figsize=(11, 3.8))

# Both the figure (the whole canvas) and the axes (the plotting area inside it)
# need the paper colour, or you get a white rectangle sitting on the page.
fig.patch.set_facecolor(PAPER)
ax.set_facecolor(PAPER)

# --- the confidence band ---------------------------------------------------
# Drawn first so it sits *behind* the line. Matplotlib stacks in call order.
# alpha is opacity: 0.18 is faint enough to read as background texture rather
# than competing with the line itself.
ax.fill_between(
    years,
    lower_bound,
    upper_bound,
    color=BRONZE,
    alpha=0.18,
    linewidth=0,          # no outline on the band — the edge would fight the line
    zorder=1,
)

# --- the zero line ---------------------------------------------------------
# The reference the whole chart is read against: "no difference from control".
# Kept thin and grey so it reads as a rule, not as data.
ax.axhline(
    y=0,
    color=MUTED,
    linewidth=0.8,
    zorder=2,
)

# --- the shock marker ------------------------------------------------------
# Vertical dashed line at year 0, when the new flight paths went live.
# Dashed so it's clearly an annotation rather than something measured.
ax.axvline(
    x=0,
    color=MUTED,
    linewidth=0.8,
    linestyle=(0, (4, 4)),  # 4 points of dash, 4 points of gap
    zorder=2,
)

# --- the coefficient line --------------------------------------------------
# Drawn last so it sits on top of everything else.
# The markers matter: they show these are eleven discrete yearly estimates,
# not a continuous measurement. A bare line would imply more precision than
# the model actually produced.
ax.plot(
    years,
    coefficients,
    color=BRONZE,
    linewidth=1.8,
    marker="o",
    markersize=4.5,
    markerfacecolor=PAPER,   # hollow markers — lighter, matches the hairline style
    markeredgecolor=BRONZE,
    markeredgewidth=1.4,
    zorder=3,
)


# ---------------------------------------------------------------------------
# STRIP THE CHROME
# ---------------------------------------------------------------------------
# Matplotlib's defaults are built for journal figures: a full box around the
# plot, heavy ticks, gridlines. All of that would look bolted-on next to the
# site's hairline rules. This removes everything that isn't carrying meaning.

# Spines are the four border lines. Top and right carry no information, so
# they go entirely. Left and bottom are kept but thinned to hairlines.
ax.spines["top"].set_visible(False)
ax.spines["right"].set_visible(False)
ax.spines["left"].set_color(RULE)
ax.spines["bottom"].set_color(RULE)
ax.spines["left"].set_linewidth(0.8)
ax.spines["bottom"].set_linewidth(0.8)

# Tick marks themselves removed; the labels stay. The labels are the useful
# part, the little protruding dashes are not.
ax.tick_params(
    axis="both",
    length=0,
    colors=MUTED,
    labelsize=10,
    pad=8,          # breathing room between the axis and its labels
)

# One tick per year, labelled with an explicit sign so the before/after split
# is readable at a glance. The minus sign here is U+2212, a proper typographic
# minus rather than a hyphen — it's wider and sits at the right height.
ax.set_xticks(years)
ax.set_xticklabels(
    [f"\u2212{abs(y)}" if y < 0 else (f"+{y}" if y > 0 else "0") for y in years]
)

# Y axis in percent. The underlying numbers are log points, which are close
# enough to percentage changes at these magnitudes that labelling them as
# percent is honest and far more readable to a non-technical reader.
ax.set_yticks([-0.15, -0.10, -0.05, 0.0, 0.05])
ax.set_yticklabels(["\u221215%", "\u221210%", "\u22125%", "0", "+5%"])

# Axis labels. Small and muted — present for the reader who wants them,
# not shouting at the one who doesn't.
ax.set_xlabel("Years from the September 2014 reroute", color=MUTED, fontsize=10, labelpad=12)

# No title. The page supplies its own heading above the image, and a title
# inside the figure would duplicate it in a mismatched font.


# ---------------------------------------------------------------------------
# EXPORT
# ---------------------------------------------------------------------------
# bbox_inches="tight" crops the surrounding whitespace, so the chart's own
# margins don't fight with the page's layout.
# facecolor has to be passed again here — savefig otherwise reverts to white,
# which would give you a white band around a paper-coloured chart.

fig.tight_layout()
fig.savefig(
    "event_study_hero.svg",
    format="svg",
    facecolor=PAPER,
    bbox_inches="tight",
)

print("Written: event_study_hero.svg")
