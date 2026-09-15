class NfeTaxAliases {
  static void applyProdutoSelecionado(
    Map<String, dynamic> item,
    Map<String, dynamic> selected,
  ) {
    _setAliases(
        item, 'cst_pis', 'cstPis', _first(selected, ['cst_pis', 'cstPis']));
    _setAliases(item, 'p_pis', 'pPis',
        _first(selected, ['p_pis', 'pPis', 'aliquota_pis', 'aliquotaPis']));
    _setAliases(item, 'cst_cofins', 'cstCofins',
        _first(selected, ['cst_cofins', 'cstCofins']));
    _setAliases(
      item,
      'p_cofins',
      'pCofins',
      _first(selected, [
        'p_cofins',
        'pCofins',
        'aliquota_cofins',
        'aliquotaCofins',
      ]),
    );
    _setAliases(item, 'p_cbs', 'pCbs',
        _first(selected, ['p_cbs', 'pCbs', 'aliquota_cbs', 'aliquotaCbs']));
    _setAliases(
      item,
      'p_ibs_uf',
      'pIbsUf',
      _first(
          selected, ['p_ibs_uf', 'pIbsUf', 'aliquota_ibs_uf', 'aliquotaIbsUf']),
    );
    _setAliases(
      item,
      'p_ibs_mun',
      'pIbsMun',
      _first(selected, [
        'p_ibs_mun',
        'pIbsMun',
        'aliquota_ibs_mun',
        'aliquotaIbsMun',
      ]),
    );
  }

  static void applyProdutoImpostoUf(
    Map<String, dynamic> item,
    Map<String, dynamic> imposto,
  ) {
    _setAliases(
        item, 'cst_pis', 'cstPis', _first(imposto, ['cstPis', 'cst_pis']));
    _setAliases(item, 'p_pis', 'pPis',
        _first(imposto, ['pPis', 'p_pis', 'aliquotaPis', 'aliquota_pis']));
    _setAliases(item, 'cst_cofins', 'cstCofins',
        _first(imposto, ['cstCofins', 'cst_cofins']));
    _setAliases(
      item,
      'p_cofins',
      'pCofins',
      _first(imposto, [
        'pCofins',
        'p_cofins',
        'aliquotaCofins',
        'aliquota_cofins',
      ]),
    );
    _setAliases(item, 'p_cbs', 'pCbs',
        _first(imposto, ['pCbs', 'p_cbs', 'aliquotaCbs', 'aliquota_cbs']));
    _setAliases(
      item,
      'p_ibs_uf',
      'pIbsUf',
      _first(
          imposto, ['pIbsUf', 'p_ibs_uf', 'aliquotaIbsUf', 'aliquota_ibs_uf']),
    );
    _setAliases(
      item,
      'p_ibs_mun',
      'pIbsMun',
      _first(imposto, [
        'pIbsMun',
        'p_ibs_mun',
        'aliquotaIbsMun',
        'aliquota_ibs_mun',
      ]),
    );
  }

  static dynamic _first(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final value = source[key];
      if (value != null && value.toString().trim().isNotEmpty) return value;
    }
    return null;
  }

  static void _setAliases(
    Map<String, dynamic> item,
    String snakeKey,
    String camelKey,
    dynamic value,
  ) {
    if (value == null) return;
    final normalized = value.toString();
    item[snakeKey] = normalized;
    item[camelKey] = normalized;
  }
}
