import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sample/core/theme/obsidian_ui_tokens.dart';
import 'package:sample/features/favorites/presentation/bloc/favorites_bloc.dart';

class FavoriteButton extends StatelessWidget {
  const FavoriteButton({super.key, required this.noteId, this.size = 22});

  final String noteId;
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = context.obsidian;

    return BlocSelector<FavoritesBloc, FavoritesState, bool>(
      selector: (state) => state.maybeWhen(
        loaded: (_, favoriteIds) => favoriteIds.contains(noteId),
        orElse: () => false,
      ),
      builder: (context, isFavorite) {
        return GestureDetector(
          onTap: () {
            context.read<FavoritesBloc>().add(FavoritesEvent.toggled(noteId));
          },
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, animation) => ScaleTransition(
                scale: animation,
                child: child,
              ),
              child: Icon(
                isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                key: ValueKey(isFavorite),
                size: size,
                color: isFavorite
                    ? const Color(0xFFEF4444)
                    : t.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ),
          ),
        );
      },
    );
  }
}
