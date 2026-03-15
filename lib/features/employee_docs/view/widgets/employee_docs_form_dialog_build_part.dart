part of 'employee_docs_form_dialog.dart';

extension _EmployeeDocsFormDialogBuild on _EmployeeDocsFormDialogState {
  Widget buildEmployeeDocsFormDialog(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isEdit = widget.initialDocument != null;

    return AlertDialog(
      title: Text(isEdit ? t.editDocument : t.addDocument),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildEmployeeSelector(t),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _docType.text,
                  items: _docTypeItems(t),
                  onChanged: (v) {
                    if (v != null) _docType.text = v;
                  },
                  decoration: InputDecoration(
                    labelText: t.documentType,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                _buildFileField(t),
                const SizedBox(height: 8),
                _buildUploadButton(t),
                if (_uploading || _saving) ...[
                  const SizedBox(height: 8),
                  _buildProgressState(t),
                ],
                const SizedBox(height: 12),
                _buildDateButtons(t),
              ],
            ),
          ),
        ),
      ),
      actions: _buildDialogActions(t),
    );
  }

  Widget _buildUploadButton(AppLocalizations t) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: (_uploading || _saving) ? null : _pickFile,
            icon: const Icon(Icons.attach_file),
            label: Text(_uploading ? t.uploading : t.uploadFile),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressState(AppLocalizations t) {
    return Column(
      children: [
        const LinearProgressIndicator(),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            _uploading ? t.uploadingDocument : t.savingDocument,
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildDialogActions(AppLocalizations t) {
    return [
      TextButton(
        onPressed: (_uploading || _saving)
            ? null
            : () => Navigator.pop(context, false),
        child: Text(t.cancel),
      ),
      ElevatedButton(
        onPressed: (_uploading || _saving) ? null : _submit,
        child: Text(_saving ? t.saving : t.save),
      ),
    ];
  }
}
