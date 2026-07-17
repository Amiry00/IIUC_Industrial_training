#!/bin/bash
find lib/presentation -type f -name "*.dart" | while read -r file; do
  sed -i 's/AppColors.background/Theme.of(context).scaffoldBackgroundColor/g' "$file"
  sed -i 's/AppColors.surface/Theme.of(context).colorScheme.surface/g' "$file"
  sed -i 's/AppColors.card/Theme.of(context).cardColor/g' "$file"
  sed -i 's/AppColors.primaryAccent/Theme.of(context).colorScheme.primary/g' "$file"
  sed -i 's/AppColors.secondaryAccent/Theme.of(context).colorScheme.secondary/g' "$file"
  sed -i 's/AppColors.primaryText/Theme.of(context).colorScheme.onSurface/g' "$file"
  sed -i 's/AppColors.secondaryText/Theme.of(context).textTheme.bodyMedium!.color!/g' "$file"
  sed -i 's/AppColors.mutedText/Theme.of(context).colorScheme.onSurface.withOpacity(0.5)/g' "$file"
  sed -i 's/AppColors.divider/Theme.of(context).dividerColor/g' "$file"
  sed -i 's/AppColors.error/Theme.of(context).colorScheme.error/g' "$file"
done
