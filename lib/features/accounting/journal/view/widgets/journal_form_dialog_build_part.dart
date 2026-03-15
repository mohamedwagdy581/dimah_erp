part of 'journal_form_dialog.dart';

extension _JournalFormDialogBuild on _JournalFormDialogState {
  Widget buildJournalFormDialog(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(t.newJournalEntry),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.event),
              label: Text(_date == null ? t.pickDate : _formatDate(_date!)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _memo,
              decoration: InputDecoration(
                labelText: t.memo,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _accountId,
              items: _accounts
                  .map(
                    (account) => DropdownMenuItem(
                      value: account.id,
                      child: Text('${account.code} - ${account.name}'),
                    ),
                  )
                  .toList(),
              onChanged: _setAccountId,
              decoration: InputDecoration(
                labelText: t.account,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _debit,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: t.debit,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _credit,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: t.credit,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(onPressed: _addLine, child: Text(t.add)),
              ],
            ),
            const SizedBox(height: 8),
            ..._lines.map(
              (line) => Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${line.accountName}: D ${line.debit} / C ${line.credit}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(t.cancel),
        ),
        ElevatedButton(onPressed: _submit, child: Text(t.save)),
      ],
    );
  }
}
