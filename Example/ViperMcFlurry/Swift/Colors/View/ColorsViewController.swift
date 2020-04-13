import Foundation
import UIKit

class ColorsViewController: UIViewController, ColorsViewInput, UITableViewDelegate, UITableViewDataSource {
    weak var output: ColorsViewOutput!

    @IBOutlet weak var tableView: UITableView!

    var colors: [ColorsViewModel] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        output.viewIsReady()
    }


    func setItems(_ items: [ColorsViewModel]) {
        self.colors = items
    }

    // MARK: - TableView Datasource & Delegate

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return colors.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Default", for: indexPath) as! ColorsTableViewCell
        return cell
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let color = colors[indexPath.row]
        color.attacher(cell)
    }

    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let color = colors[indexPath.row]
        color.detacher()
    }

}
