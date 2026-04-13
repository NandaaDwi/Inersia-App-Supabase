import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:inersia_supabase/features/user/profile/providers/draft_provider.dart';

class MyArticleSearchBar extends HookConsumerWidget {
  const MyArticleSearchBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useTextEditingController();
    final isFocused = useState(false);
    final focusNode = useFocusNode();

    useEffect(() {
      void listener() => isFocused.value = focusNode.hasFocus;
      focusNode.addListener(listener);
      return () => focusNode.removeListener(listener);
    }, [focusNode]);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: const Color(0xFF161616),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isFocused.value
                ? const Color(0xFF2563EB).withOpacity(0.7)
                : const Color(0xFF1F2937),
            width: isFocused.value ? 1.5 : 0.5,
          ),
        ),
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          textInputAction: TextInputAction.search,
          onChanged: (v) =>
              ref.read(articleSearchQueryProvider.notifier).state = v,
          decoration: InputDecoration(
            hintText: 'Cari artikel...',
            hintStyle: const TextStyle(color: Color(0xFF4B5563), fontSize: 14),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: Color(0xFF6B7280),
              size: 20,
            ),
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFF6B7280),
                      size: 18,
                    ),
                    onPressed: () {
                      controller.clear();
                      ref.read(articleSearchQueryProvider.notifier).state = '';
                      focusNode.unfocus();
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 13),
          ),
        ),
      ),
    );
  }
}
