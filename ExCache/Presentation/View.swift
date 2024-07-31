//
//  View.swift
//  ExCache
//
//  Created by 강동영 on 7/31/24.
//

import UIKit

class View: UIView {
    private let searchTextfield: UITextField = {
        let textfield: UITextField = .init(frame: .zero)
        textfield.translatesAutoresizingMaskIntoConstraints = false
        textfield.placeholder = "게임, 앱, 스토리 등"
        return textfield
    }()
    
    private lazy var tableView: UITableView = {
        let tableView: UITableView = .init(frame: .zero)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(AppListCell.self, forCellReuseIdentifier: AppListCell.reuseIdentifier)
        return tableView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(searchTextfield)
        NSLayoutConstraint.activate([
            searchTextfield.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            searchTextfield.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            searchTextfield.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension View: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: AppListCell.reuseIdentifier, for: indexPath)
        guard let convertedCell = cell as? AppListCell else { return cell }
        return convertedCell
    }
}

fileprivate final class AppListCell: UITableViewCell {
    static let reuseIdentifier: String = String(describing: AppListCell.self)
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
