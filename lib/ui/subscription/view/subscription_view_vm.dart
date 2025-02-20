// Dart imports:
import 'dart:async';

// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';

// Project imports:
import 'package:invoiceninja_flutter/constants.dart';
import 'package:invoiceninja_flutter/data/models/models.dart';
import 'package:invoiceninja_flutter/data/models/subscription_model.dart';
import 'package:invoiceninja_flutter/redux/app/app_actions.dart';
import 'package:invoiceninja_flutter/redux/app/app_state.dart';
import 'package:invoiceninja_flutter/redux/subscription/subscription_actions.dart';
import 'package:invoiceninja_flutter/redux/ui/ui_actions.dart';
import 'package:invoiceninja_flutter/ui/subscription/subscription_screen.dart';
import 'package:invoiceninja_flutter/ui/subscription/view/subscription_view.dart';
import 'package:invoiceninja_flutter/utils/completers.dart';
import 'package:invoiceninja_flutter/utils/localization.dart';

class SubscriptionViewScreen extends StatelessWidget {
  const SubscriptionViewScreen({
    Key key,
    this.isFilter = false,
  }) : super(key: key);
  static const String route = '/$kSettings/$kSettingsSubscriptionsView';
  final bool isFilter;

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, SubscriptionViewVM>(
      converter: (Store<AppState> store) {
        return SubscriptionViewVM.fromStore(store);
      },
      builder: (context, vm) {
        return SubscriptionView(
          viewModel: vm,
          isFilter: isFilter,
        );
      },
    );
  }
}

class SubscriptionViewVM {
  SubscriptionViewVM({
    @required this.state,
    @required this.subscription,
    @required this.company,
    @required this.onEntityAction,
    @required this.onRefreshed,
    @required this.isSaving,
    @required this.onBackPressed,
    @required this.isLoading,
    @required this.isDirty,
  });

  factory SubscriptionViewVM.fromStore(Store<AppState> store) {
    final state = store.state;
    final subscription =
        state.subscriptionState.map[state.subscriptionUIState.selectedId] ??
            SubscriptionEntity(id: state.subscriptionUIState.selectedId);

    Future<Null> _handleRefresh(BuildContext context) {
      final completer = snackBarCompleter<Null>(
          context, AppLocalization.of(context).refreshComplete);
      store.dispatch(LoadSubscription(
          completer: completer, subscriptionId: subscription.id));
      return completer.future;
    }

    return SubscriptionViewVM(
      state: state,
      company: state.company,
      isSaving: state.isSaving,
      isLoading: state.isLoading,
      isDirty: subscription.isNew,
      subscription: subscription,
      onRefreshed: (context) => _handleRefresh(context),
      onBackPressed: () {
        store.dispatch(UpdateCurrentRoute(SubscriptionScreen.route));
      },
      onEntityAction: (BuildContext context, EntityAction action) =>
          handleEntitiesActions([subscription], action, autoPop: true),
    );
  }

  final AppState state;
  final SubscriptionEntity subscription;
  final CompanyEntity company;
  final Function(BuildContext, EntityAction) onEntityAction;
  final Function(BuildContext) onRefreshed;
  final Function onBackPressed;
  final bool isSaving;
  final bool isLoading;
  final bool isDirty;
}
