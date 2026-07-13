import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/profile_view_model.dart';
import '../../viewmodels/auth_view_model.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController _nameCtrl = TextEditingController();
  bool _didScheduleLoad = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    if (!_didScheduleLoad) {
      _didScheduleLoad = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final vm = context.read<ProfileViewModel>();
        await vm.loadProfile();
        
        if (mounted && vm.profile != null) {
          _nameCtrl.text = vm.profile!.displayName;
        }
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProfileViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              final authVM = context.read<AuthViewModel>();
              await authVM.logout();
              
              if (!context.mounted) return;
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
          ),
        ],
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: GestureDetector(
                      onTap: vm.pickAndUploadAvatar,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            key: ValueKey(vm.profile?.avatarUrl),
                            radius: 50,
                            backgroundImage: vm.profile?.avatarUrl != null
                                ? NetworkImage(vm.profile!.avatarUrl!)
                                : null,
                            child: vm.profile?.avatarUrl == null
                                ? const Icon(Icons.person, size: 50)
                                : null,
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(8),
                            child: const Icon(
                              Icons.edit,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Display Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      if (_nameCtrl.text.trim().isEmpty) return;
                      
                      FocusScope.of(context).unfocus();
                      await vm.updateDisplayName(_nameCtrl.text);
                      
                      if (!context.mounted) return;
                      
                      if (vm.errorMessage != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(vm.errorMessage!)),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Profile updated successfully!')),
                        );
                      }
                    },
                    child: const Text('Save Changes'),
                  ),
                ],
              ),
            ),
    );
  }
}