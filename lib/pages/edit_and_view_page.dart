import 'package:apple_notes_clone/widgets/bottom_bar.dart';
import 'package:apple_notes_clone/widgets/edit_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import 'package:apple_notes_clone/models/folders_provider.dart';
import 'package:apple_notes_clone/models/notes_provider.dart';
import 'package:apple_notes_clone/widgets/custom_back_button.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class EditViewPage extends StatefulWidget {
  const EditViewPage({
    Key? key,
    required this.noteId,
    required this.folderId,
    required this.isNewNote,
    required this.isQuickNote,
  }) : super(key: key);
  final String noteId;
  final String folderId;
  final bool isNewNote;
  final bool isQuickNote;

  @override
  State<EditViewPage> createState() => _EditViewPageState();
}

class _EditViewPageState extends State<EditViewPage> {
  //* variables
  Notes? currentNote;
  Document _document = Document();

  @override
  void initState() {
    //getting the current note
    currentNote = (widget.isNewNote)
        ? Notes(content: '', folderId: widget.folderId)
        : Provider.of<NotesDataProvider>(context, listen: false)
            .getNoteById(widget.noteId);
    putOldValueInEditor();

    super.initState();
  }
  // *methods

//To put the initial value of the note in the eidtor
  void putOldValueInEditor() {
    _document = Document()..insert(0, currentNote!.content);
    setState(
      () {
        _controller = QuillController(
          document: _document,
          selection: const TextSelection.collapsed(offset: 0),
        );
      },
    );
  }

  //for going back
  void navigateBack(BuildContext context) {
    changeNotes(context, currentNote!, _controller.document.toPlainText());
    Navigator.pop(context);
  }

  //getting folder name for the back button
  String getFolderName() {
    return Provider.of<FolderDataProvider>(context)
        .getFolderNameById(widget.folderId);
  }

  // if it is a new note creating a new object and then passing the data into the new
  //object if nto updating the existing data
  void changeNotes(BuildContext context, Notes currentNote, String content) {
    if (widget.isNewNote) {
      Provider.of<NotesDataProvider>(context, listen: false)
          .addNewNote(currentNote);
    }
    Provider.of<NotesDataProvider>(context, listen: false)
        .updateExistingNote(content, currentNote);
  }

  void sendToGoogleGenerativeAI() async {
    print(_controller.document.toPlainText());
    // Make sure to include this import:
    // import 'package:google_generative_ai/google_generative_ai.dart';
    final model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: "AIzaSyBWqOgz3ASk0smZ4VX0FxMW84nI2pEhL9o",
    );

    // Prompt for organizing, tagging, and returning the original text content
    final prompt = '''
Organize the following notes by giving each a meaningful title, relevant tags, and include the original text content. Ensure the tags describe the purpose, category, or context of each note.

Notes:
${_controller.document.toPlainText()}

Example output:
[
  {
    "index": 0,
    "title": "Meet up with girlfriend",
    "tags": ["social", "relationships"],
    "content": "meet up with my girlfriend"
  },
  {
    "index": 1,
    "title": "Picnic plan for tomorrow",
    "tags": ["recreation", "outdoor"],
    "content": "go to picnic tomorrow"
  },
  {
    "index": 2,
    "title": "Flutter Amplify Integration",
    "tags": ["work", "development", "AWS"],
    "content": "amplify integration for flutter"
  }
]
''';

    // Generating organized content with original text included
    final response = await model.generateContent([Content.text(prompt)]);
    debugPrint(response.text, wrapWidth: 1024);
  }

//* controllers
  QuillController _controller = QuillController.basic();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    return WillPopScope(
      onWillPop: () async {
        changeNotes(context, currentNote!, _controller.document.toPlainText());
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          leading:
              Consumer<FolderDataProvider>(builder: (context, value, child) {
            return CustomBackButton(
                text: widget.isQuickNote ? "Folders" : getFolderName(),
                navigationFunction: navigateBack);
          }),
          leadingWidth: double.infinity,
          actions: [
            IconButton(
                onPressed: () {},
                icon: const Icon(
                  CupertinoIcons.ellipsis_vertical_circle,
                  color: CupertinoColors.systemYellow,
                ))
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: QuillEditor(
                controller: _controller,
                configurations: const QuillEditorConfigurations(
                  expands: true,
                  autoFocus: false,
                  scrollable: true,
                  placeholder: 'Start typing...',
                  padding: EdgeInsets.all(15),
                ),
                focusNode: _focusNode,
                scrollController: _scrollController,
              ),
            ),
            BottomBar(
                child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                    height: 40,
                    child: SvgPicture.asset(
                        isDarkMode
                            ? "assets/checklist_dark.svg"
                            : "assets/checklist_light.svg",
                        width: 35)),
                GestureDetector(
                    onTap: sendToGoogleGenerativeAI,
                    child: const Icon(CupertinoIcons.camera)),
                const Icon(CupertinoIcons.pencil_outline),
                const EditButton(
                    initiateQuickNote: true, callingFolderId: "quicknotes")
              ],
            ))
          ],
        ),
      ),
    );
  }
}
