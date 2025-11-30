import 'package:flutter/material.dart';
import '../../services/security_service.dart';

import 'mlkit_localization_provider.dart';

class BannedPage extends StatelessWidget {
  const BannedPage({super.key});

  @override
  Widget build(BuildContext context) {
    final SecurityService securityService = SecurityService.instance;
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.red.shade900,
              Colors.black,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Banned Icon
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.red, width: 3),
                    ),
                    child: const Icon(
                      Icons.block,
                      size: 60,
                      color: Colors.red,
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Title
                  Builder(
                    builder: (context) {
                      return Text(
                        securityService.isPermanentlyBlocked 
                            ? 'PERMANENTLY BANNED' 
                            : context.translateWithMLKit((l) => l.accessDenied),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }
                  ),

                  const SizedBox(height: 20),
                  
                  // Message
                  Builder(
                    builder: (context) {
                      return Text(
                        securityService.isPermanentlyBlocked
                            ? 'Your account has been permanently banned due to violations of our terms of service. All your data has been removed from the platform.'
                            : context.translateWithMLKit((l) => l.accountRestricted),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 16,
                          height: 1.5,
                        ),
                      );
                    }
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Reason
                  if (securityService.blockReason.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        children: [
                          Builder(
                            builder: (context) {
                              return Text(
                                '${context.translateWithMLKit((l) => l.reason)}:',
                                style: TextStyle(
                                  color: Colors.red.shade300,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            }
                          ),
                          const SizedBox(height: 8),
                          Text(
                            securityService.blockReason,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 40),
                  
                  // Warning
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange.shade300),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Builder(
                            builder: (context) {
                              return Text(
                                securityService.isPermanentlyBlocked
                                    ? 'This action is permanent and cannot be reversed.'
                                    : context.translateWithMLKit((l) => l.alternativeAccess),
                                style: TextStyle(
                                  color: Colors.orange.shade300,
                                  fontSize: 13,
                                ),
                              );
                            }
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Contact Info
                  Text(
                    'Raha misy fanontaniana dia antsoy ny 034 29 439 71 na mandefasa emailaka @ manassehrandriamitsiry@gmail.com',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}