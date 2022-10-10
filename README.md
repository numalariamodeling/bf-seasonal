## Seasonality calibration in Burkina
1. Run 30 years of simulation with habitat multiplier of 1 and monthly habitats spline specified in the `monthly_habitats_xxx.csv` file
2. Analyze using `analyze_pfprcases.py`. You can use the argparse here: `python {path_to_analyze_script} -name {output_folder_name} -id {expt_id}`
3. Using `plot_seasonality_comparison_treated.R` in the `output_processor` to compare with routine cases.
4. Adjust monthly habitats spline (I usually leave constant and maxhab unchanged)
5. Repeat 1-4 till you're happy

### Detail about run 30 years
- Case management influences how seasonality curve looks, I fix it to 50% coverage here.
- The calibration target is average routine case data over 5 from 2015 to 2018. The monthly numbers are normalized yearly (i.e., monthly_cases / sum of all monthly cases, each done separately for 2015, 2016, ...) Same was done for simulated data, and we use incidence of *treated cases* here.
- Only the last 3 years of simulation were taken for calibration
- In general, the momentum in the system, rather than the magnitude of monthly multiplier, is dictating the monthly incidence
- It is generally wise to tune one or two (consecutive) months at a time, and from left to right (January -> December)
- The system also have inertia: if you have a peak on say September, you kind of see another bulk of infections in November or December, sort of like a ripple effect!

### Expected workflow in calibrating other DS
- Start with Bittou's monthly numbers, leave constant and maxhab untouched
- The last best fitted monthly value for Bittou is: `0.001,0.001,0.0007,0.0007,0.0007,0.007,0.015,0.031,0.08,0.01,0.001,0.001`

