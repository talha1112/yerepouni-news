import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app_theme.dart';
import '../models/config.dart';
import '../services/feed_service.dart' show resolveImageUrl;

class AppDrawer extends StatefulWidget {
  const AppDrawer({
    super.key,
    required this.config,
    required this.onSelectCategory,
    required this.onSelectLanguage,
    required this.onOpenToday,
  });

  final AppConfig config;
  final void Function(NewsCategory category) onSelectCategory;
  final void Function(String languageId) onSelectLanguage;
  final VoidCallback onOpenToday;

  static const _todayInHistoryLabel = 'ՊԱՏՄՈՒԹԵԱՆ ՄԷՋ ԱՅՍՕՐ';

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  String? expandedLang;

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 330,
      child: Column(
        children: [
          Container(
            height: 86,
            color: AppColors.accent,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                if (widget.config.brand.logo.isNotEmpty)
                  Image.network(resolveImageUrl(widget.config.brand.logo), height: 45, errorBuilder: (_, __, ___) => const SizedBox()),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 13),
                  child: Text('LANGUAGES & CATEGORIES',
                      style: TextStyle(
                          fontSize: 10, letterSpacing: 1.3, color: AppColors.muted, fontWeight: FontWeight.w800)),
                ),
                ...widget.config.languages.map((lang) {
                  final isOpen = expandedLang == lang.id;
                  final cats = widget.config.categoriesFor(lang.id);
                  return Container(
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: AppColors.divider)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: () {
                            setState(() => expandedLang = isOpen ? null : lang.id);
                            widget.onSelectLanguage(lang.id);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(lang.label,
                                    style: const TextStyle(fontFamily: 'Georgia', fontSize: 18)),
                                Icon(isOpen ? Icons.expand_less : Icons.chevron_right, color: AppColors.accent),
                              ],
                            ),
                          ),
                        ),
                        if (isOpen)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ...cats.map((c) => InkWell(
                                      onTap: () => widget.onSelectCategory(c),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
                                        child: Text(c.displayName,
                                            style: const TextStyle(color: Color(0xFF625A67))),
                                      ),
                                    )),
                                InkWell(
                                  onTap: widget.onOpenToday,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
                                    child: Text(AppDrawer._todayInHistoryLabel,
                                        style: const TextStyle(color: Color(0xFF625A67))),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 14),
                _FooterLink(label: 'Contact Us', onTap: () => _open(widget.config.contact)),
                _FooterLink(label: 'Website', onTap: () => _open(widget.config.website)),
                _FooterLink(label: 'Facebook', onTap: () => _open(widget.config.facebook)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  const _FooterLink({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.divider)),
        ),
        child: Text(label, style: const TextStyle(color: AppColors.accent, fontSize: 14)),
      ),
    );
  }
}
