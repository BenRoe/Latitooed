# Coordinate Field Editing Reformatting

## Symptom

Manual latitude/longitude editing felt broken. Deleting text caused the field to snap back or rewrite the value while typing.

## Cause

Every valid edit updated the selected coordinate and then immediately synced the field text back to the formatted six-decimal display value.

## Fix

Manual field updates now update `selectedCoordinate` without re-syncing the field text. Formatting still happens when coordinates are set from non-typing actions such as map clicks or search-result selection.

## Verification

Click a coordinate field, delete characters, and type a new value. The field should preserve the exact in-progress text until another action explicitly sets the coordinate.

