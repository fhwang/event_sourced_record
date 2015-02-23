[[[0.2.0]] - Feb 23 2015]

* BUGFIX - allow multiple calculators (#11).
* Included the configuration for the `data` column in the generated Event class
  (#9).
* Made Event instances immutable (#8).
* Added `occurred_at` to generated events, which will be used by the calculator
  for ordering events. If `occurred_at` is not defined, `created_at` will be
  used instead (#6).
