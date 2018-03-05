//
//  MainViewController.swift
//  Peggy Meter
//
//  Created by Artem Iglikov on 3/4/18.
//  Copyright © 2018 PeggyJo. All rights reserved.
//

import UIKit
import Charts
import PassiveDataKit

class MainViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var dataController: DataController!
    var transmitter: PDKHttpTransmitter!
    let dateFormatter = DateFormatter()

    @IBOutlet weak var historyTableView: UITableView!
    @IBOutlet var moodButtons: [UIButton]!
    @IBOutlet weak var lineChartView: LineChartView!
    
    let smileys: [String] = ["☹️", "🙂", "😀"]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        dataController = DataController()

        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium
        
        for (index, moodButton) in moodButtons.enumerated() {
            moodButton.setTitle(smileys[index], for: .normal)
        }
        
        startPDK()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func startPDK() {
        let transOpts = [
            PDK_TRANSMITTER_UPLOAD_URL_KEY: "https://us-central1-peggy-192804.cloudfunctions.net/ingest-test",
            PDK_SOURCE_KEY: "test_ios",
            PDK_TRANSMITTER_ID_KEY: "test_user_ios"
        ]
        
        transmitter = PDKHttpTransmitter(options: transOpts)
        
        let pdk = PassiveDataKit.sharedInstance()!
        pdk.register(transmitter, for: PDKDataGenerator.location)
        pdk.register(transmitter, for: PDKDataGenerator.battery)
        //pdk.register(transmitter, for: PDKDataGenerator.pedometer)
        pdk.register(transmitter, for: PDKDataGenerator.appleHealthKit)
        pdk.add(transmitter)
    }

    func updateChart() {
        var points: [ChartDataEntry] = []
        for (index, moodRecord) in self.dataController.getMoodRecords().enumerated() {
            points.append(ChartDataEntry(x: Double(index), y: Double(moodRecord.moodLevel)))
        }
        lineChartView.data = LineChartData(dataSet: LineChartDataSet(values: points, label: ""))
        lineChartView.notifyDataSetChanged()
    }

    @IBAction func toggleGraphButtonClicked(_ sender: Any) {
        self.lineChartView.isHidden = !self.lineChartView.isHidden
        self.historyTableView.isHidden = !self.historyTableView.isHidden
    }
    
    @IBAction func moodLevelButtonClicked(_ sender: Any) {
        let alert = UIAlertController(title: "Feeling \((sender as! UIButton).titleLabel!.text ?? "normal")", message: "Enter a comment (optional)", preferredStyle: .alert)
        
        alert.addTextField { (textField) in
            textField.placeholder = "Just god a job offer!"
        }
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
            let textField = alert!.textFields![0]
            print("Text field: \(String(describing: textField.text))")
            
            let record: MoodRecord = MoodRecord()
            record.moodLevel = (sender as! UIButton).tag
            record.comment = textField.text!
            self.dataController.saveMoodRecord(record)
            
            self.historyTableView.reloadData()
            self.updateChart()
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView,
                   heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 64.0
    }
    
    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        return self.dataController.getMoodRecords().count
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "MoodRecordCell")!
        let record: MoodRecord = self.dataController.getMoodRecords()[indexPath.row]
        (cell.viewWithTag(1) as! UILabel).text = dateFormatter.string(from: record.timestamp)
        (cell.viewWithTag(2) as! UILabel).text = self.smileys[record.moodLevel - 1]
        (cell.viewWithTag(3) as! UILabel).text = record.comment
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            self.dataController.deleteMoodRecord(self.dataController.getMoodRecords()[indexPath.row])
            tableView.deleteRows(at: [indexPath], with: .fade)
            self.updateChart()
        }
    }
}