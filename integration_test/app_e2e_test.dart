import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:devcohort_lms/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('DevCohort LMS E2E Integration Test', () {
    testWidgets('Core Assignment Flow: Instructor Create -> Student Submit', (tester) async {
      // 1. Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Scenario Part A: The Teacher Flow
      print('--- SCENARIO PART A: TEACHER FLOW ---');
      
      // Enter Email and Password
      await tester.enterText(find.byKey(const Key('emailField')), 'hazeem@gmail.com');
      await tester.enterText(find.byKey(const Key('passwordField')), 'password123');
      await tester.tap(find.byKey(const Key('loginButton')));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Verify Instructor Dashboard
      expect(find.text('Instructor Dashboard'), findsOneWidget);

      // Tap on the first cohort (Assuming it exists and has text)
      // Since we don't know the exact name, we find the first ListTile or Card that looks like a cohort
      final cohortFinder = find.byType(ListTile).first;
      await tester.tap(cohortFinder);
      await tester.pumpAndSettle();

      // Tap on a Week (Assuming first week)
      await tester.tap(find.textContaining('Week').first);
      await tester.pumpAndSettle();

      // Tap "Add Assignment"
      await tester.tap(find.text('Add Assignment'));
      await tester.pumpAndSettle();

      // Enter details
      await tester.enterText(find.widgetWithText(TextField, 'Assignment Title'), 'E2E Test Assignment');
      await tester.enterText(find.widgetWithText(TextField, 'Markdown Instructions'), 'This is an automated E2E test description.');
      
      // Tap "Create"
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      // Open Drawer and Logout
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();

      print('--- SCENARIO PART B: STUDENT FLOW ---');
      
      // Return to Login and Enter Student Credentials
      await tester.enterText(find.byKey(const Key('emailField')), 'hazeem1@gmail.com');
      await tester.enterText(find.byKey(const Key('passwordField')), 'password123');
      await tester.tap(find.byKey(const Key('loginButton')));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Verify Student Dashboard
      expect(find.text('DevCohort Student'), findsOneWidget);

      // Tap Notification Bell
      await tester.tap(find.byIcon(Icons.notifications_none));
      await tester.pumpAndSettle();
      
      // Verify Notification exists
      expect(find.textContaining('E2E Test Assignment'), findsWidgets);
      
      // Close notifications (tap outside or back)
      await tester.tapAt(const Offset(10, 10)); 
      await tester.pumpAndSettle();

      // Navigate to Cohort -> Week
      await tester.tap(find.byType(ExpansionTile).first);
      await tester.pumpAndSettle();

      // Tap "E2E Test Assignment"
      await tester.tap(find.text('E2E Test Assignment'));
      await tester.pumpAndSettle();

      // Tap Submit
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();

      // Paste GitHub URL
      await tester.enterText(find.byKey(const Key('githubUrlField')), 'https://github.com/test/repo');
      await tester.pumpAndSettle();
      
      // Hit "Submit My Work"
      await tester.tap(find.byKey(const Key('submitWorkButton')));
      await tester.pumpAndSettle();

      // Verify status updates (Search for the Passed/Submitted badge)
      expect(find.textContaining('SUBMITTED'), findsWidgets);
    });
  });
}
