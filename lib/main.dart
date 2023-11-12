import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:contacts_service/contacts_service.dart';

void main() {
  runApp(const MaterialApp(title: 'Phone-Book by Julie', home: MyApp()));
}

//stless => StatelessWidget 자동생성
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

// class UserType {
//   final String name;
//   final String number;
//   UserType({required this.name, required this.number});
// }
// List<UserType> names=[UserType(name:'김영희',number:'01011112222')]



class FilterData {
  final String name;
  final String value;

  FilterData({required this.name, required this.value});
}

final List<FilterData> filterList = [
  FilterData(name: '오름차순', value: 'ascending'),
  FilterData(name: '내림차순', value: 'descending'),
];

List<Contact> names = [];

class _MyAppState extends State<MyApp> {
  late TextEditingController nameController; // TextField Controller
  late TextEditingController numberController;
  String filterValue = filterList[0].value;


  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    numberController = TextEditingController();
    getPermission();

  }

  @override
  void dispose() {
    nameController.dispose();
    numberController.dispose();
    super.dispose();
  }

  void getContact()async{
    List<Contact> contacts = await ContactsService.getContacts();
    setState(() {
      names=contacts;
    });

  }

  void getPermission()async{
    final status= await Permission.contacts.status;
    late String message='';
    if(status.isGranted){
      // 연락처를 꺼냄
      message='승인 되었 습니다.';
      getContact();
      runFilter(filterList[0].value);
    } else if(status.isDenied){
      message='거절 되었 습니다.';
      Permission.contacts.request();
      openAppSettings(); //앱 설정 화면 띄움.
      // 한 두번 거절하면 팝업이 안뜨게 설정되므로, 앱 셋팅 띄우게 함.
    }
    print(message);
  }


  //Filter 동작 함수
  void runFilter(String value) {
    if (value.isEmpty) {
      return;
    } else if (value == 'descending') {
      setState(() {
        names.sort((a, b) => b.givenName!.compareTo(a.givenName as String));
      });
    } else if (value == 'ascending') {
      setState(() {
        names.sort((a, b) => a.givenName!.compareTo(b.givenName as String));
      });
    }
  }

  void onSubmit() async{
    // setState(() {
    //   names = [
    //     ...names,
    //     UserType(name: nameController.text, number: numberController.text)
    //   ];
    // });
    Contact newPerson= Contact();
    newPerson.givenName=nameController.text;
    newPerson.phones=[Item(label: "", value:numberController.text )];
    await ContactsService.addContact(newPerson);
    getContact();
    runFilter(filterValue);
  }

  void onDelete(Contact user)async {
    // List 삭제 하는 코드
    // setState(() {
    //   names.removeWhere((item) => item.name == name);
    // });
    await ContactsService.deleteContact(user);
    getContact();
  }

  void onSelectFilter(String value) {
    setState(() {
      filterValue = value;
    });
    runFilter(value);
  }

  @override
  Widget build(context) {
    // context : 부모에 대한 정보들
    //MaterialApp 위젯이 MyApp에 있다면, context는 null이 됨.
    // MaterialApp을 밖으로 뺴면 context가 MaterialApp이 됨. 그래서 밖으로 빼는거임.
    return Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            setState(() {
              nameController.text = '';
              numberController.text = '';
            });
            showDialog(
                context: context,
                builder: (context) {
                  return CustomModal(
                      nameController: nameController,
                      numberController: numberController,
                      onSubmit: onSubmit);
                });
          },
          child: Icon(Icons.add),
        ),
        appBar: AppBar(
          title: Text('전화번호부 만들기'),
          actions: [IconButton(
              onPressed: null,
              icon: Icon(
                Icons.contacts,
                color: Colors.white,
                size: 20,
              ))],
          backgroundColor: Colors.amber,
          elevation: 5,
          // 그림자 정도
          centerTitle: true, // title 가운데 정렬
        ),
        body: Column(
          children: [
            Container(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [CustomDropdown(onSelectFilter: onSelectFilter)],
              ),
            ),
            Expanded(
                child: ListView.builder(
                    itemCount: names.length,
                    itemBuilder: (context, index) {
                      return ContactBox(user: names[index], onDelete: onDelete);
                      return Text('');
                    }))
          ],
        ),
        bottomNavigationBar: CustomBottomBar());
  }
}

class CustomDropdown extends StatefulWidget {
  final onSelectFilter;

  const CustomDropdown({super.key, required this.onSelectFilter});

  @override
  State<CustomDropdown> createState() => _CustomDropdownState();
}

class _CustomDropdownState extends State<CustomDropdown> {
  //filter init value
  @override
  Widget build(BuildContext context) {
    return DropdownMenu(
      initialSelection: filterList[0].value, //dropdown 초기 값
      onSelected: (String? value) {
        widget.onSelectFilter(value);
      }, //onChange (value 는 무조건 String 으로 오는 듯)
      dropdownMenuEntries: filterList
          .map<DropdownMenuEntry<String>>((FilterData elem) =>
                  DropdownMenuEntry(value: elem.value, label: elem.name)
              // filterArray.map<DropdownMenuEntry<Value 타입>>((elem type)=> DropdownMenuEntry(value:value 타입 으로 오는 값, label:String))
              )
          .toList(),
    );
  }
}

class CustomModal extends StatefulWidget {
  final nameController;
  final onSubmit;
  final numberController;

  const CustomModal(
      {super.key,
      required this.nameController,
      required this.numberController,
      required this.onSubmit});

  @override
  State<CustomModal> createState() => _CustomModalState();
}

class _CustomModalState extends State<CustomModal> {
  late FocusNode nameFocus;
  late FocusNode numberFocus;

  @override
  void initState() {
    super.initState();
    nameFocus = FocusNode();
    numberFocus = FocusNode();
  }

  Widget build(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    return Dialog(
        child: Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(4)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, //height auto
        children: [
          Text(
            "Contact",
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 24),
          ),
          Form(
            key: _formKey,
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(0, 8, 0, 16),
                  child: TextFormField(
                    controller: widget.nameController,
                    autofocus: true,
                    focusNode: nameFocus,
                    decoration: InputDecoration(
                        hintText: '이름을 입력해 주세요.',
                        prefixIcon: Icon(Icons.person)),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        nameFocus.requestFocus();
                        return '이름을 입력해 주세요.';
                      }
                      if (value.length > 10) {
                        nameFocus.requestFocus();
                        return '10자 이내로 입력해 주세요.';
                      }
                      return null;
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(0, 0, 0, 32),
                  child: TextFormField(
                    focusNode: numberFocus,
                    controller: widget.numberController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        numberFocus.requestFocus();
                        return '전화 번호를 입력해 주세요.';
                      }
                      if (value.length > 11) {
                        numberFocus.requestFocus();
                        return '11자 이내로 입력해 주세요.';
                      }
                      if (!RegExp('[0-9]').hasMatch(value)) {
                        numberFocus.requestFocus();
                        return '숫자로 입력해 주세요.';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                        hintText: '번호를 입력해 주세요.',
                        prefixIcon: Icon(Icons.phone)),
                  ),
                )
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('Cancel')),
              Padding(padding: EdgeInsets.all(8)),
              TextButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // 성공 했을 때
                      widget.onSubmit();
                      Navigator.pop(context);
                    }
                  },
                  child: Text('OK'))
            ],
          )
        ],
      ),
    ));
  }
}

class CustomBottomBar extends StatelessWidget {
  const CustomBottomBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      padding: EdgeInsets.all(10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Icon(Icons.phone),
          Icon(Icons.message),
          Icon(Icons.contact_page),
        ],
      ),
    );
  }
}

class ContactBox extends StatefulWidget {
  final user;
  final onDelete;

  const ContactBox({super.key, required this.user, required this.onDelete});

  @override
  State<ContactBox> createState() => _ContactBoxState();
}

class _ContactBoxState extends State<ContactBox> {
  @override // 중복 발생 할 때 내꺼 먼저 적용해 달라는 의미
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.white10,
      ),
      child: ListTile(
        leading: SizedBox(
            width: 36,
            height: 36,
            child: CircleAvatar(
              backgroundColor: Colors.black,
              child: Icon(
                Icons.person,
                color: Colors.white,
              ),
            )),
        title: Text(
          widget.user.givenName,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
        subtitle: Padding(
          padding: EdgeInsets.fromLTRB(0, 8, 0, 0),
          child: Text(
              widget.user.phones[0].value.replaceAllMapped(
              RegExp(r'(\d{3})(\d{3,4})(\d{4})'),
              (m) => '${m[1]}-${m[2]}-${m[3]}')
          ),
        ),
        trailing: Wrap(
          spacing: 16,
          children: [
            // ElevatedButton.icon(
            //   style: ElevatedButton.styleFrom(padding: EdgeInsets.all(6)),
            //   onPressed: () {
            //     // widget.onDelete(widget.user);
            //   },
            //   icon: Icon(
            //     Icons.edit,
            //     size: 14,
            //   ),
            //   label: Text('Edit'),
            // ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red, padding: EdgeInsets.all(6)),
              onPressed: () {
                widget.onDelete(widget.user);
              },
              icon: Icon(
                Icons.delete,
                size: 14,
              ),
              label: Text('Delete'),
            )
          ],
        ),
      ),
    );
  }
}
