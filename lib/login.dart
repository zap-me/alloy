import 'package:flutter/material.dart';
import 'package:email_validator/email_validator.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:zapdart/colors.dart';
import 'package:zapdart/utils.dart';

import 'beryllium.dart';
import 'widgets.dart';
import 'prefs.dart';
import 'config.dart';

part 'login.freezed.dart';

class AccountRegistration {
  final String firstName;
  final String lastName;
  final String email;
  final String mobileNumber;
  final String address;
  final String currentPassword;
  final String newPassword;
  final String? photo;
  final String? photoType;

  AccountRegistration(
      this.firstName,
      this.lastName,
      this.email,
      this.mobileNumber,
      this.address,
      this.currentPassword,
      this.newPassword,
      this.photo,
      this.photoType);
}

class AccountLogin {
  final String email;
  final String password;
  final String tfCode;
  final bool? tfRequired;

  AccountLogin(this.email, this.password, this.tfCode, this.tfRequired);

  AccountLogin copyWithoutTfRequired() {
    return AccountLogin(email, password, tfCode, false);
  }
}

class AccountRequestApiKey {
  final String email;
  final String deviceName;

  AccountRequestApiKey(this.email, this.deviceName);
}

// This class will be returned by BronzeLoginForm, BronzeRegisterForm etc
// to prompt which container should be pushed to the stack next
@freezed
class LoginChoice with _$LoginChoice {
  const factory LoginChoice.doLogin() = LCDoLogin;
  const factory LoginChoice.doRegistration() = LCDoRegistration;
  const factory LoginChoice.doApiKeyRequest() = LCDApiKeyRequest;
  const factory LoginChoice.registration(AccountRegistration reg) =
      LCRegistration;
  const factory LoginChoice.login(AccountLogin login) = LCLogin;
  const factory LoginChoice.apiKeyRequest(AccountRequestApiKey req) =
      LCRequestApiKey;
}

class Acct {
  String? email;
  String? apiKey;

  Acct(this.email, this.apiKey);
}

@freezed
class LoginResult with _$LoginResult {
  const factory LoginResult.acct(Acct acct) = LRAcct;
  const factory LoginResult.reset() = LRReset;
  const factory LoginResult.retry() = LRRetry;
  const factory LoginResult.nothing() = LRNothing;
}

FormFieldValidator emailValidate = (value) {
  value = value?.trim();
  if (value == null || value.isEmpty) return 'Please enter an email';
  if (!EmailValidator.validate(value)) return 'Invalid email';
  return null;
};

class BronzeRequestApiKeyForm extends StatefulWidget {
  final String deviceName;
  final String? instructions;

  BronzeRequestApiKeyForm(this.deviceName, {this.instructions}) : super();

  @override
  BronzeRequestApiKeyFormState createState() {
    return BronzeRequestApiKeyFormState();
  }
}

class BronzeRequestApiKeyFormState extends State<BronzeRequestApiKeyForm> {
  final TextEditingController _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @protected
  @mustCallSuper
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: PreferredSize(
          child: Container(),
          preferredSize: Size(0, 0),
        ),
        body: BiforgePage(
            scrollChild: true,
            showDebugInfo: true,
            child: Form(
                key: _formKey,
                child: BigLogoContainer(
                  children: <Widget>[
                    Text(
                      "Forgot Password",
                      style: TextStyle(
                          color: Color(0xFFFFFFFF).withOpacity(0.75),
                          fontSize: 20),
                    ),
                    VerticalSpacer(height: 10),
                    Text(widget.instructions == null
                        ? "Enter your email to login via email link"
                        : widget.instructions!),
                    VerticalSpacer(),
                    BronzeFormInput(_emailController,
                        icon: Icon(Icons.email_outlined),
                        labelText: 'Email',
                        keyboardType: TextInputType.emailAddress,
                        validator: emailValidate),
                    VerticalSpacer(),
                    BronzeRoundedButton(() {
                      if (_formKey.currentState == null) return;
                      if (_formKey.currentState!.validate()) {
                        var loginChoice = LoginChoice.apiKeyRequest(
                            AccountRequestApiKey(_emailController.text.trim(),
                                widget.deviceName));
                        Navigator.of(context).pop(loginChoice);
                      }
                    }, ZapOnPrimary, ZapPrimary, ZapPrimaryGradient, 'Continue',
                        fwdArrow: true,
                        width: ButtonWidth,
                        height: ButtonHeight),
                    VerticalSpacer(height: 8),
                    WordDivider(),
                    VerticalSpacer(height: 8),
                    BronzeRoundedButton(() {
                      Navigator.of(context).pop(LoginChoice.doLogin());
                    }, ZapOnSurface, ZapSurface, null, 'Login',
                        fwdArrow: true,
                        width: ButtonWidth,
                        height: ButtonHeight),
                  ],
                ))));
  }
}

class BronzeLoginForm extends StatefulWidget {
  final AccountLogin? login;
  final bool showTwoFactorCode;
  final bool? twoFactorRequired;

  BronzeLoginForm(this.login,
      {this.showTwoFactorCode = false, this.twoFactorRequired})
      : super();

  @override
  BronzeLoginFormState createState() {
    return BronzeLoginFormState();
  }
}

class BronzeLoginFormState extends State<BronzeLoginForm> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _tfCodeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @protected
  @mustCallSuper
  void initState() {
    super.initState();

    if (widget.login != null) {
      _emailController.text = widget.login!.email;
      _passwordController.text = widget.login!.password;
    }
  }

  String? passwordValidate(value) {
    if (value == null || value.isEmpty) return 'Please enter a password';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: PreferredSize(
          child: Container(),
          preferredSize: Size(0, 0),
        ),
        body: BiforgePage(
            scrollChild: true,
            showDebugInfo: true,
            child: Form(
                key: _formKey,
                child: BigLogoContainer(
                  children: [
                    Text(
                      "Welcome back!",
                      style: TextStyle(
                          color: Color(0xFFFFFFFF).withOpacity(0.75),
                          fontSize: 20),
                    ),
                    VerticalSpacer(height: 10),
                    Text(
                      "Please log in",
                      style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 34),
                    ),
                    VerticalSpacer(),
                    BronzeFormInput(
                      _emailController,
                      validator: emailValidate,
                      icon: Icon(Icons.person_outline),
                      keyboardType: TextInputType.emailAddress,
                      labelText: 'Email',
                    ),
                    VerticalSpacer(),
                    BronzeFormInput(_passwordController,
                        icon: Icon(Icons.key_outlined),
                        validator: passwordValidate,
                        labelText: 'Password',
                        obscureText: true,
                        toggleObscure: true),
                    VerticalSpacer(),
                    Visibility(
                      visible: widget.showTwoFactorCode,
                      child: BronzeFormInput(_tfCodeController,
                          icon: Icon(Icons.lock_outline),
                          labelText: 'Two factor login code'),
                    ),
                    VerticalSpacer(height: widget.showTwoFactorCode ? 15 : 0),
                    BronzeRoundedButton(() {
                      if (_formKey.currentState == null) return;
                      if (_formKey.currentState!.validate()) {
                        var loginChoice = LoginChoice.login(AccountLogin(
                            _emailController.text.trim(),
                            _passwordController.text,
                            _tfCodeController.text,
                            widget.twoFactorRequired));
                        Navigator.of(context).pop(loginChoice);
                      }
                    }, ZapOnPrimary, ZapPrimary, ZapPrimaryGradient, 'Continue',
                        fwdArrow: true,
                        width: ButtonWidth,
                        height: ButtonHeight),
                    VerticalSpacer(height: 5),
                    BronzeRoundedButton(() {
                      Navigator.of(context).pop(LoginChoice.doApiKeyRequest());
                    }, ZapOnSurface, ZapSurface, null, 'Lost Password',
                        fwdArrow: true,
                        width: ButtonWidth,
                        height: ButtonHeight),
                    VerticalSpacer(height: 8),
                    WordDivider(),
                    VerticalSpacer(height: 8),
                    BronzeRoundedButton(() {
                      Navigator.of(context).pop(LoginChoice.doRegistration());
                    }, ZapOnSurface, ZapSurface, null, 'Create an Account',
                        fwdArrow: true,
                        width: ButtonWidth,
                        height: ButtonHeight),
                  ],
                ))));
  }
}

class BronzeRegisterForm extends StatefulWidget {
  BronzeRegisterForm();

  @override
  BronzeRegisterFormState createState() {
    return BronzeRegisterFormState();
  }
}

class BronzeRegisterFormState extends State<BronzeRegisterForm> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _passwordConfirmController =
      TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @protected
  @mustCallSuper
  void initState() {
    super.initState();
  }

  String? newPasswordValidate(value) {
    if (value == null || value.isEmpty) return 'Please enter a new password';
    return null;
  }

  String? passwordConfirmValidate(value) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != _newPasswordController.text) return 'Password does not match';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: PreferredSize(
          child: Container(),
          preferredSize: Size(0, 0),
        ),
        body: BiforgePage(
            scrollChild: true,
            showDebugInfo: true,
            child: Form(
                key: _formKey,
                child: BigLogoContainer(children: [
                  Text(
                    "Hi there!",
                    style: TextStyle(
                        color: Color(0xFFFFFFFF).withOpacity(0.75),
                        fontSize: 20),
                  ),
                  VerticalSpacer(height: 10),
                  Text(
                    "Let's sign up",
                    style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 34),
                  ),
                  VerticalSpacer(),
                  BronzeFormInput(_emailController,
                      icon: Icon(Icons.email_outlined),
                      labelText: 'Email',
                      keyboardType: TextInputType.emailAddress,
                      validator: emailValidate),
                  VerticalSpacer(),
                  BronzeFormInput(
                    _newPasswordController,
                    icon: Icon(Icons.key_outlined),
                    obscureText: true,
                    toggleObscure: true,
                    labelText: 'New Password',
                    validator: newPasswordValidate,
                  ),
                  VerticalSpacer(),
                  BronzeFormInput(
                    _passwordConfirmController,
                    icon: Icon(Icons.key_outlined),
                    obscureText: true,
                    toggleObscure: true,
                    labelText: 'Password Confirmation',
                    validator: passwordConfirmValidate,
                  ),
                  VerticalSpacer(),
                  BronzeRoundedButton(() async {
                    if (_formKey.currentState == null) return;
                    if (_formKey.currentState!.validate()) {
                      var loginChoice = LoginChoice.registration(
                          AccountRegistration(
                              '',
                              '',
                              _emailController.text.trim(),
                              '',
                              '',
                              '',
                              _newPasswordController.text,
                              null,
                              null));
                      Navigator.of(context).pop(loginChoice);
                    }
                  }, ZapOnPrimary, ZapPrimary, ZapPrimaryGradient, 'Continue',
                      fwdArrow: true, width: ButtonWidth, height: ButtonHeight),
                  VerticalSpacer(height: 8),
                  WordDivider(),
                  VerticalSpacer(height: 8),
                  BronzeRoundedButton(() {
                    Navigator.of(context).pop(LoginChoice.doLogin());
                  }, ZapOnSurface, ZapSurface, null, 'Login',
                      fwdArrow: true, width: ButtonWidth, height: ButtonHeight),
                ]))));
  }
}

class StagingForm extends StatefulWidget {
  final bool invalidAuth;
  final bool retry;
  final String? errTitle;
  final String? errMessage;
  StagingForm(this.invalidAuth, this.retry, this.errTitle, this.errMessage);

  @override
  StagingFormState createState() {
    return StagingFormState();
  }
}

class StagingFormState extends State<StagingForm> {
  @override
  void initState() {
    super.initState();
    if (!widget.invalidAuth && !widget.retry)
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => startLoginProcess(LoginChoice.doRegistration()));
    else
      WidgetsBinding.instance.addPostFrameCallback((_) => alert(context,
          '${widget.errTitle ?? "unknown error"}', '${widget.errMessage}'));
  }

  Future<void> _loginErrorAlert(BuildContext context, BeError error) async {
    await error.when(network: () async {
      await alert(context, 'Network error',
          'A network error occured when trying to login');
    }, auth: (msg) async {
      await alert(context, 'Authentication failed',
          'The login details you entered are not valid ($msg)');
    }, format: () async {
      await alert(context, 'Format error',
          'A format error occured when trying to login');
    });
  }

  Future<Acct?> _beLogin(BuildContext context, AccountLogin login,
      {bool silent: false}) async {
    var devName = await deviceName();
    var result = await beApiKeyCreate(
        login.email, login.password, devName, login.tfCode);
    return await result.when<Future<Acct?>>((apikey) async {
      // write api key
      await Prefs.beApiKeySet(apikey.token);
      await Prefs.beApiSecretSet(apikey.secret);
      return Acct(login.email, apikey.token);
    }, error: (err) async {
      if (!silent) await _loginErrorAlert(context, err);
      return null;
    });
  }

  Future<LoginResult> _beRegister(
      BuildContext context, AccountRegistration reg) async {
    showAlertDialog(context, 'registering..');
    var res = await beUserRegister(reg);
    Navigator.pop(context);
    var acct = await res.when((content) async {
      var cancelled = false;
      Acct? acct;
      showAlertDialog(context,
          'we are sending you a confirmation email, please follow the link in the email to confirm...',
          showCancel: true, onCancel: () => cancelled = true, maxLines: null);
      while (acct == null && !cancelled) {
        await Future.delayed(Duration(seconds: 5));
        // save account if login successful
        acct = await _beLogin(
            context, AccountLogin(reg.email, reg.newPassword, '', false),
            silent: true);
      }
      Navigator.pop(context);
      return acct;
    }, error: (err) async {
      await err.when(
          network: () async => await alert(context, 'Network error',
              'A network error occured when trying to register'),
          auth: (msg) async => await alert(context, 'Authorisation error',
              'An authorisation error occured when trying to register ($msg)'),
          format: () async => await alert(context, 'Format error',
              'A format error occured when trying to register'));
      return null;
    });
    if (acct == null) return LoginResult.nothing();
    return LoginResult.acct(acct);
  }

  Future<LoginResult> _beLoginWithTwoFactor(
      BuildContext context, AccountLogin login) async {
    showAlertDialog(context, 'logging in..');
    var acct = await _beLogin(context, login);
    Navigator.pop(context);
    if (acct == null) return LoginResult.nothing();
    return LoginResult.acct(acct);
  }

  Future<LoginResult> _beLoginCheckTwoFactor(
      BuildContext context, AccountLogin login) async {
    showAlertDialog(context, 'logging in..');
    var result = await beUserTwoFactorEnabledCheck(login.email, login.password);
    Navigator.pop(context);
    var tfEnabled =
        await result.when((enabled) async => enabled, error: (err) async {
      await _loginErrorAlert(context, err);
      return null;
    });
    if (tfEnabled == null) return LoginResult.nothing();
    if (!tfEnabled)
      return _processLoginChoice(
          LoginChoice.login(login.copyWithoutTfRequired()));
    // get the two factor code if required
    var loginChoice = await Navigator.push<LoginChoice?>(
      context,
      MaterialPageRoute(
          builder: (context) => BronzeLoginForm(login,
              showTwoFactorCode: true, twoFactorRequired: true)),
    );
    if (loginChoice == null) LoginResult.nothing();
    return await _processLoginChoice(loginChoice!);
  }

  Future<Acct?> _beApiKeyClaim(
      BuildContext context, AccountRequestApiKey req, String token,
      {silent: false}) async {
    var result = await beApiKeyClaim(token);
    return await result.when<Future<Acct?>>((apikey) async {
      // write api key
      await Prefs.beApiKeySet(apikey.token);
      await Prefs.beApiSecretSet(apikey.secret);
      return Acct(req.email, apikey.token);
    }, error: (err) async {
      if (!silent) await _loginErrorAlert(context, err);
      return null;
    });
  }

  Future<LoginResult> _beApiKeyRequest(
      BuildContext context, AccountRequestApiKey req) async {
    var result = await beApiKeyRequest(req.email, req.deviceName);
    return await result.when((token) async {
      Acct? acct;
      var cancelled = false;
      showAlertDialog(context,
          'we are sending you a confirmation email, please follow the link in the email to confirm...',
          showCancel: true, onCancel: () => cancelled = true, maxLines: null);
      while (acct == null && !cancelled) {
        await Future.delayed(Duration(seconds: 5));
        // claim api key
        acct = await _beApiKeyClaim(context, req, token, silent: true);
      }
      Navigator.pop(context);
      if (acct != null) return LoginResult.acct(acct);
      return LoginResult.nothing();
    }, error: (err) async {
      await alert(context, 'Network error',
          'A network error occured when trying to login');
      return LoginResult.nothing();
    });
  }

  Future<LoginResult> _login() async {
    var loginChoice = await Navigator.push<LoginChoice>(
      context,
      MaterialPageRoute(
          builder: (context) =>
              BronzeLoginForm(null, showTwoFactorCode: false)),
    );
    if (loginChoice == null) return LoginResult.nothing();
    return await _processLoginChoice(loginChoice);
  }

  Future<LoginResult> _register() async {
    var loginChoice = await Navigator.push<LoginChoice>(
      context,
      MaterialPageRoute(builder: (context) => BronzeRegisterForm()),
    );
    if (loginChoice == null) return LoginResult.nothing();
    return await _processLoginChoice(loginChoice);
  }

  Future<LoginResult> _loginWithEmail() async {
    // request api key form
    var devName = await deviceName();
    var loginChoice = await Navigator.push<LoginChoice>(
      context,
      MaterialPageRoute(builder: (context) => BronzeRequestApiKeyForm(devName)),
    );
    if (loginChoice == null) return LoginResult.nothing();
    return await _processLoginChoice(loginChoice);
  }

  Future<LoginResult> _processLoginChoice(LoginChoice loginChoice) async {
    return await loginChoice.when(
      login: (AccountLogin login) async {
        if (login.tfRequired == null)
          return await _beLoginCheckTwoFactor(context, login);
        return await _beLoginWithTwoFactor(context, login);
      },
      registration: (reg) async => await _beRegister(context, reg),
      apiKeyRequest: (req) async => await _beApiKeyRequest(context, req),
      doLogin: () async => await _login(),
      doRegistration: () async => await _register(),
      doApiKeyRequest: () async => await _loginWithEmail(),
    );
  }

  void startLoginProcess(LoginChoice loginChoice) {
    _processLoginChoice(loginChoice)
        .then((value) => Navigator.pop(context, value));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: PreferredSize(
          child: Container(),
          preferredSize: Size(0, 0),
        ),
        body: BiforgePage(
            scrollChild: true,
            showDebugInfo: true,
            child: BigLogoContainer(children: [
              BronzeRoundedButton(
                  () => startLoginProcess(LoginChoice.doLogin()),
                  ZapOnPrimary,
                  ZapPrimary,
                  ZapPrimaryGradient,
                  'Login',
                  fwdArrow: true,
                  width: ButtonWidth,
                  height: ButtonHeight),
              BronzeRoundedButton(
                  () => startLoginProcess(LoginChoice.doRegistration()),
                  ZapOnSurface,
                  ZapSurface,
                  null,
                  'Create an Account',
                  fwdArrow: true,
                  width: ButtonWidth,
                  height: ButtonHeight),
              widget.invalidAuth
                  ? BronzeRoundedButton(
                      () => Navigator.pop(context, LoginResult.reset()),
                      ZapOnSurface,
                      ZapSurface,
                      null,
                      'Reset',
                      fwdArrow: true,
                      width: ButtonWidth,
                      height: ButtonHeight)
                  : SizedBox(),
              widget.retry
                  ? BronzeRoundedButton(
                      () => Navigator.pop(context, LoginResult.retry()),
                      ZapOnSurface,
                      ZapSurface,
                      null,
                      'Retry',
                      fwdArrow: true,
                      width: ButtonWidth,
                      height: ButtonHeight)
                  : SizedBox(),
            ])));
  }
}
