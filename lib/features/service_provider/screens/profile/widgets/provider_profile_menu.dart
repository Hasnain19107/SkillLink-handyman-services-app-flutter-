import 'package:flutter/material.dart';

import '../../../../../core/widgets/dialogs/theme_selector_dialog.dart';
import '../../../../../services/auth/auth_service.dart';
import '../../../../help_support/screens/help_support_screen.dart';

class ProviderProfileMenu extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;
  final bool showDivider;

  const ProviderProfileMenu({
    Key? key,
    required this.title,
    required this.icon,
    required this.onTap,
    this.iconColor,
    this.showDivider = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor ?? Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Theme.of(context)
                      .colorScheme
                      .onBackground
                      .withOpacity(0.5),
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            indent: 16,
            endIndent: 16,
            color: Theme.of(context).dividerColor,
          ),
      ],
    );
  }
}

class ProviderProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Widget? trailing;

  const ProviderProfileMenuItem({
    Key? key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(
        icon,
        color: theme.colorScheme.primary,
        size: 24,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: theme.textTheme.titleMedium?.color,
        ),
      ),
      trailing: trailing ??
          Icon(
            Icons.chevron_right,
            color: theme.iconTheme.color,
            size: 24,
          ),
      onTap: onTap,
    );
  }
}

class ProviderProfileMenuList extends StatelessWidget {
  final Function onEditProfile;
  final Function onManageServices;
  final Function onSignOut;
  final Function onDeleteAccount;
  final AuthService _authService = AuthService();

  ProviderProfileMenuList({
    Key? key,
    required this.onEditProfile,
    required this.onManageServices,
    required this.onSignOut,
    required this.onDeleteAccount,
  }) : super(key: key);

  void _handleSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              onSignOut(); // Use the provided callback
              _authService.signOutAndNavigateToLogin(context);
            },
            child: const Text(
              "Logout",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ProviderProfileMenuItem(
          title: 'Edit Profile',
          icon: Icons.edit,
          onTap: () => onEditProfile(),
        ),
        ProviderProfileMenuItem(
          title: 'Manage Services',
          icon: Icons.business_center,
          onTap: () => onManageServices(),
        ),
        ProviderProfileMenuItem(
          title: 'Theme',
          icon: Icons.color_lens,
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => const ThemeSelectorDialog(),
            );
          },
        ),
        ProviderProfileMenuItem(
          title: 'Notifications',
          icon: Icons.notifications,
          onTap: () {
            Navigator.pushNamed(context, '/notifications');
          },
        ),
        ProviderProfileMenuItem(
          title: 'Help & Support',
          icon: Icons.help,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const HelpSupportScreen(),
              ),
            );
          },
        ),
        ProviderProfileMenuItem(
          title: 'Sign Out',
          icon: Icons.logout,
          onTap: () => _handleSignOut(context),
          trailing: null,
        ),
        ProviderProfileMenuItem(
          title: 'Delete Account',
          icon: Icons.delete,
          onTap: () => onDeleteAccount(),
        ),
      ],
    );
  }
}
