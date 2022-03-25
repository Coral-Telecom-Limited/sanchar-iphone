/*
 * Copyright (c) 2010-2020 Belledonne Communications SARL.
 *
 * This file is part of linphone-iphone
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */


import UIKit
import Foundation
import linphonesw

@objc class ConferenceHistoryDetailsView:  BackNextNavigationView, UICompositeViewDelegate, UITableViewDataSource {
	

	let participantsListTableView = UITableView()
	let conectionsListTableView = UITableView()
	let participantsLabel = StyledLabel(VoipTheme.conference_scheduling_font, "  "+VoipTexts.conference_schedule_participants_list)
	let datePicker = StyledDatePicker(pickerMode: .date, readOnly:true)
	let timePicker = StyledDatePicker(pickerMode: .time, readOnly:true)

	var conferenceData : ScheduledConferenceData?  {
		didSet {
			if let data = conferenceData {
				super.titleLabel.text = data.subject.value!
				self.participantsListTableView.reloadData()
				self.participantsListTableView.removeConstraints().done()
				self.participantsListTableView.matchParentSideBorders().alignUnder(view: participantsLabel,withMargin: self.form_margin).done()
				self.participantsListTableView.height(Double(data.conferenceInfo.participants.count) * VoipParticipantCell.cell_height).done()
				datePicker.liveValue = MutableLiveData(conferenceData!.rawDate)
				timePicker.liveValue = MutableLiveData(conferenceData!.rawDate)
			}
		}
	}
	
	
	static let compositeDescription = UICompositeViewDescription(ConferenceHistoryDetailsView.self, statusBar: StatusBarView.self, tabBar: nil, sideMenu: SideMenuView.self, fullscreen: false, isLeftFragment: false,fragmentWith: nil)
	static func compositeViewDescription() -> UICompositeViewDescription! { return compositeDescription }
	func compositeViewDescription() -> UICompositeViewDescription! { return type(of: self).compositeDescription }
	
	override func viewDidLoad() {
		
		super.viewDidLoad(
			backAction: {
				PhoneMainView.instance().popView(self.compositeViewDescription())
			},nextAction: {
			},
			nextActionEnableCondition: MutableLiveData(false),
			title:"")
		super.nextButton.isHidden = true
		
		
		let schedulingStack = UIStackView()
		schedulingStack.axis = .vertical
		contentView.addSubview(schedulingStack)
		schedulingStack.alignParentTop(withMargin: 2*form_margin).matchParentSideBorders(insetedByDx: form_margin).done()
		
		let scheduleForm = UIView()
		schedulingStack.addArrangedSubview(scheduleForm)
		scheduleForm.matchParentSideBorders().done()
		
		// Left column (Date & Time)
		let leftColumn = UIView()
		scheduleForm.addSubview(leftColumn)
		leftColumn.matchParentWidthDividedBy(2.2).alignParentLeft(withMargin: form_margin).alignParentTop(withMargin: form_margin).done()
		
		let dateLabel = StyledLabel(VoipTheme.conference_scheduling_font, VoipTexts.conference_schedule_date)
		leftColumn.addSubview(dateLabel)
		dateLabel.alignParentLeft().alignParentTop(withMargin: form_margin).done()
				
		leftColumn.addSubview(datePicker)
		datePicker.alignParentLeft().alignUnder(view: dateLabel,withMargin: form_margin).matchParentSideBorders().done()
		
		leftColumn.wrapContentY().done()

		// Right column (Duration & Timezone)
		let rightColumn = UIView()
		scheduleForm.addSubview(rightColumn)
		rightColumn.matchParentWidthDividedBy(2.2).alignParentRight(withMargin: form_margin).alignParentTop().done()
		
		let timeLabel = StyledLabel(VoipTheme.conference_scheduling_font, VoipTexts.conference_schedule_time)
		rightColumn.addSubview(timeLabel)
		timeLabel.alignParentLeft().alignParentTop(withMargin: form_margin).done()
		
		rightColumn.addSubview(timePicker)
		timePicker.alignParentLeft().alignUnder(view: timeLabel,withMargin: form_margin).matchParentSideBorders().done()
	
		rightColumn.wrapContentY().done()

		scheduleForm.wrapContentY().done()
		
		// Participants
		participantsLabel.backgroundColor = VoipTheme.voipFormBackgroundColor.get()
		contentView.addSubview(participantsLabel)
		participantsLabel.matchParentSideBorders().height(form_input_height).alignUnder(view: schedulingStack,withMargin: form_margin*2).done()
		participantsLabel.textAlignment = .left
		
		contentView.addSubview(participantsListTableView)
		participantsListTableView.isScrollEnabled = false
		participantsListTableView.dataSource = self
		participantsListTableView.register(VoipParticipantCell.self, forCellReuseIdentifier: "VoipParticipantCellSSchedule")
		participantsListTableView.allowsSelection = false
		if #available(iOS 15.0, *) {
			participantsListTableView.allowsFocus = false
		}
		participantsListTableView.separatorStyle = .singleLine
		participantsListTableView.separatorColor = VoipTheme.light_grey_color
				
		// Goto chat - v2
		/*
		let chatButton = FormButton(title: VoipTexts.conference_go_to_chat.uppercased(), backgroundStateColors: VoipTheme.primary_colors_background)
		contentView.addSubview(chatButton)
		chatButton.onClick {
			//let chatRoom = ChatRoom()
			//PhoneMainView.instance().go(to: chatRoom?.getCobject)
		}
		
		chatButton.centerX().alignParentBottom(withMargin: 3*self.form_margin).alignUnder(view: participantsListTableView,withMargin: 3*self.form_margin).done()
		 */
		 
	}
	
	
	// Objc - bridge, as can't access easily to the view model.
	@objc func setCallLog(callLog:OpaquePointer) {
		let log = CallLog.getSwiftObject(cObject: callLog)
		if let conferenceInfo = log.conferenceInfo {
			self.conferenceData = ScheduledConferenceData(conferenceInfo: conferenceInfo)
		}
		//self.callLog = log
	}
	
	
	// TableView datasource delegate
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		guard let data = conferenceData else {
			return 0
		}
		return data.conferenceInfo.participants.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell:VoipParticipantCell = tableView.dequeueReusableCell(withIdentifier: "VoipParticipantCellSSchedule") as! VoipParticipantCell
		guard let data = conferenceData else {
			return cell
		}
		cell.selectionStyle = .none
		cell.scheduleConfParticipantAddress = data.conferenceInfo.participants[indexPath.row]
		cell.limeBadge.isHidden = true
		return cell
	}
	
	
}
