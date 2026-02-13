import SwiftUI

// MARK: - Add Contact View
struct AddContactView: View {
    @EnvironmentObject var appState: AppState
    @Binding var isPresented: Bool
    @State private var currentStep: ContactFormStep = .parentInfo
    
    // Parent Info
    @State private var parentName = ""
    @State private var phoneNumber = ""
    @State private var email = ""
    @State private var alternatePhone = ""
    @State private var address = ""
    @State private var occupation = ""
    @State private var relationship: Parent.ParentRelationship = .mother
    @State private var notes = ""
    
    // Student Info
    @State private var students: [StudentFormData] = []
    @State private var showAddStudent = false
    
    // School Info
    @State private var selectedSchoolId = "school-1"
    
    var isFormValid: Bool {
        !parentName.isEmpty && !phoneNumber.isEmpty
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            AddContactHeader(
                isPresented: $isPresented,
                currentStep: currentStep,
                canSave: isFormValid && currentStep == .review,
                onSave: saveContact
            )
            
            SubtleDivider()
            
            // Progress Steps
            ContactFormProgress(currentStep: currentStep)
            
            SubtleDivider()
            
            // Content
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    switch currentStep {
                    case .parentInfo:
                        parentInfoSection
                    case .studentInfo:
                        studentInfoSection
                    case .review:
                        reviewSection
                    }
                }
                .padding(Spacing.xl)
            }
            .background(Color.moltBackground)
            
            SubtleDivider()
            
            // Footer Navigation
            ContactFormFooter(
                currentStep: $currentStep,
                isFormValid: isFormValid
            )
        }
        .frame(width: 600, height: 700)
        .background(Color.moltSurface)
        .sheet(isPresented: $showAddStudent) {
            AddStudentSheet(isPresented: $showAddStudent) { student in
                students.append(student)
            }
        }
    }
    
    // MARK: - Parent Info Section
    var parentInfoSection: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            SectionHeader(title: "Parent/Guardian Information", icon: "person.fill")
            
            FormCard {
                VStack(spacing: Spacing.lg) {
                    FormTextField(
                        label: "Full Name",
                        placeholder: "e.g., Parent 01",
                        text: $parentName,
                        isRequired: true
                    )
                    
                    HStack(spacing: Spacing.md) {
                        FormTextField(
                            label: "Phone Number",
                            placeholder: "+234 801 234 5678",
                            text: $phoneNumber,
                            isRequired: true,
                            keyboardType: .phone
                        )
                        
                        FormTextField(
                            label: "Alternate Phone",
                            placeholder: "+234 802 345 6789",
                            text: $alternatePhone
                        )
                    }
                    
                    FormTextField(
                        label: "Email Address",
                        placeholder: "parent@email.com",
                        text: $email
                    )
                    
                    FormPicker(
                        label: "Relationship",
                        selection: $relationship,
                        options: Parent.ParentRelationship.allCases
                    )
                }
            }
            
            SectionHeader(title: "Additional Information", icon: "info.circle")
            
            FormCard {
                VStack(spacing: Spacing.lg) {
                    FormTextField(
                        label: "Occupation",
                        placeholder: "e.g., Banker, Engineer",
                        text: $occupation
                    )
                    
                    FormTextField(
                        label: "Home Address",
                        placeholder: "Full address",
                        text: $address
                    )
                    
                    FormTextArea(
                        label: "Notes",
                        placeholder: "Any special notes or preferences...",
                        text: $notes
                    )
                }
            }
        }
    }
    
    // MARK: - Student Info Section
    var studentInfoSection: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            SectionHeader(title: "Children/Students", icon: "graduationcap.fill")
            
            if students.isEmpty {
                EmptyStudentCard(onAdd: { showAddStudent = true })
            } else {
                VStack(spacing: Spacing.md) {
                    ForEach(students.indices, id: \.self) { index in
                        StudentCard(
                            student: students[index],
                            onEdit: { /* Edit logic */ },
                            onDelete: { students.remove(at: index) }
                        )
                    }
                    
                    AddMoreStudentButton(onAdd: { showAddStudent = true })
                }
            }
            
            SectionHeader(title: "School", icon: "building.columns.fill")
            
            FormCard {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    Text("School")
                        .font(.moltLabel)
                        .foregroundColor(.moltTextSecondary)
                    
                    HStack {
                        Image(systemName: "building.columns.fill")
                            .foregroundColor(.moltPrimary)
                        
                        Text(School.mock.name)
                            .font(.moltBody)
                            .foregroundColor(.moltTextPrimary)
                        
                        Spacer()
                        
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.priorityLow)
                    }
                    .padding(Spacing.md)
                    .background(Color.moltSurfaceSecondary)
                    .cornerRadius(CornerRadius.medium)
                    
                    if let address = School.mock.address {
                        Text(address)
                            .font(.moltCaption)
                            .foregroundColor(.moltTextMuted)
                    }
                }
            }
        }
    }
    
    // MARK: - Review Section
    var reviewSection: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            SectionHeader(title: "Review Contact", icon: "checkmark.shield.fill")
            
            // Parent Summary
            FormCard {
                VStack(spacing: Spacing.md) {
                    HStack {
                        ZStack {
                            Circle()
                                .fill(Color.moltPrimary.opacity(0.15))
                                .frame(width: 60, height: 60)
                            
                            Text(parentName.prefix(1).uppercased())
                                .font(.moltTitleMedium)
                                .foregroundColor(.moltPrimary)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(parentName)
                                .font(.moltTitleSmall)
                                .foregroundColor(.moltTextPrimary)
                            
                            Text(relationship.displayName)
                                .font(.moltCaption)
                                .foregroundColor(.moltTextSecondary)
                        }
                        
                        Spacer()
                    }
                    
                    SubtleDivider()
                    
                    ReviewInfoRow(icon: "phone.fill", label: "Phone", value: phoneNumber)
                    
                    if !email.isEmpty {
                        ReviewInfoRow(icon: "envelope.fill", label: "Email", value: email)
                    }
                    
                    if !occupation.isEmpty {
                        ReviewInfoRow(icon: "briefcase.fill", label: "Occupation", value: occupation)
                    }
                    
                    if !address.isEmpty {
                        ReviewInfoRow(icon: "location.fill", label: "Address", value: address)
                    }
                }
            }
            
            // Students Summary
            if !students.isEmpty {
                SectionHeader(title: "Enrolled Children", icon: "person.2.fill")
                
                ForEach(students.indices, id: \.self) { index in
                    FormCard {
                        StudentReviewRow(student: students[index])
                    }
                }
            }
            
            // Notes
            if !notes.isEmpty {
                SectionHeader(title: "Notes", icon: "note.text")
                
                FormCard {
                    Text(notes)
                        .font(.moltBody)
                        .foregroundColor(.moltTextSecondary)
                }
            }
        }
    }
    
    func saveContact() {
        guard isFormValid else { return }
        let payload = ParentCreatePayload(
            whatsappId: phoneNumber.isEmpty ? nil : phoneNumber,
            phoneNumber: phoneNumber,
            name: parentName,
            email: email.isEmpty ? nil : email,
            alternatePhone: alternatePhone.isEmpty ? nil : alternatePhone,
            address: address.isEmpty ? nil : address,
            occupation: occupation.isEmpty ? nil : occupation,
            relationship: relationship.rawValue,
            notes: notes.isEmpty ? nil : notes,
            studentNames: students.map { $0.name }
        )
        _Concurrency.Task {
            do {
                _ = try await appState.createParent(payload)
                await MainActor.run {
                    isPresented = false
                }
            } catch {
                print("Failed to create parent: \(error)")
            }
        }
    }
}

// MARK: - Contact Form Step
enum ContactFormStep: Int, CaseIterable {
    case parentInfo = 0
    case studentInfo = 1
    case review = 2
    
    var title: String {
        switch self {
        case .parentInfo: return "Parent Info"
        case .studentInfo: return "Children"
        case .review: return "Review"
        }
    }
    
    var icon: String {
        switch self {
        case .parentInfo: return "person.fill"
        case .studentInfo: return "graduationcap.fill"
        case .review: return "checkmark.circle.fill"
        }
    }
}

// MARK: - Student Form Data
struct StudentFormData: Identifiable {
    let id = UUID()
    var name: String
    var grade: String
    var classSection: String
    var admissionNumber: String
    var dateOfBirth: Date?
    var gender: Student.Gender
}

// MARK: - Add Contact Header
struct AddContactHeader: View {
    @Binding var isPresented: Bool
    let currentStep: ContactFormStep
    let canSave: Bool
    let onSave: () -> Void
    
    var body: some View {
        HStack {
            Button(action: { isPresented = false }) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.moltTextSecondary)
                    .frame(width: 32, height: 32)
                    .background(Color.moltSurfaceSecondary)
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            Text("Add New Contact")
                .font(.moltTitleSmall)
                .foregroundColor(.moltTextPrimary)
            
            Spacer()
            
            if canSave {
                Button(action: onSave) {
                    Text("Save")
                        .font(.moltBody)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, Spacing.lg)
                        .padding(.vertical, Spacing.sm)
                        .background(Color.moltPrimary)
                        .cornerRadius(CornerRadius.medium)
                }
                .buttonStyle(.plain)
            } else {
                Color.clear.frame(width: 80, height: 32)
            }
        }
        .padding(Spacing.lg)
        .background(Color.moltSurface)
    }
}

// MARK: - Contact Form Progress
struct ContactFormProgress: View {
    let currentStep: ContactFormStep
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(ContactFormStep.allCases, id: \.self) { step in
                HStack(spacing: Spacing.xs) {
                    ZStack {
                        Circle()
                            .fill(step.rawValue <= currentStep.rawValue ? Color.moltPrimary : Color.moltSurfaceSecondary)
                            .frame(width: 28, height: 28)
                        
                        if step.rawValue < currentStep.rawValue {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        } else {
                            Text("\(step.rawValue + 1)")
                                .font(.moltLabel)
                                .fontWeight(.medium)
                                .foregroundColor(step.rawValue <= currentStep.rawValue ? .white : .moltTextMuted)
                        }
                    }
                    
                    Text(step.title)
                        .font(.moltCaption)
                        .foregroundColor(step == currentStep ? .moltTextPrimary : .moltTextMuted)
                }
                
                if step != ContactFormStep.allCases.last {
                    Rectangle()
                        .fill(step.rawValue < currentStep.rawValue ? Color.moltPrimary : Color.moltDivider)
                        .frame(height: 2)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, Spacing.sm)
                }
            }
        }
        .padding(Spacing.lg)
        .background(Color.moltSurface)
    }
}

// MARK: - Contact Form Footer
struct ContactFormFooter: View {
    @Binding var currentStep: ContactFormStep
    let isFormValid: Bool
    
    var body: some View {
        HStack {
            if currentStep != .parentInfo {
                Button(action: previousStep) {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "chevron.left")
                        Text("Previous")
                    }
                    .font(.moltBody)
                    .foregroundColor(.moltTextSecondary)
                }
                .buttonStyle(.plain)
            }
            
            Spacer()
            
            if currentStep != .review {
                Button(action: nextStep) {
                    HStack(spacing: Spacing.xs) {
                        Text("Next")
                        Image(systemName: "chevron.right")
                    }
                    .font(.moltBody)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.sm)
                    .background(isFormValid || currentStep != .parentInfo ? Color.moltPrimary : Color.moltTextMuted)
                    .cornerRadius(CornerRadius.medium)
                }
                .buttonStyle(.plain)
                .disabled(!isFormValid && currentStep == .parentInfo)
            }
        }
        .padding(Spacing.lg)
        .background(Color.moltSurface)
    }
    
    func nextStep() {
        if let nextIndex = ContactFormStep.allCases.firstIndex(where: { $0 == currentStep })?.advanced(by: 1),
           nextIndex < ContactFormStep.allCases.count {
            withAnimation(.easeInOut(duration: 0.2)) {
                currentStep = ContactFormStep.allCases[nextIndex]
            }
        }
    }
    
    func previousStep() {
        if let prevIndex = ContactFormStep.allCases.firstIndex(where: { $0 == currentStep })?.advanced(by: -1),
           prevIndex >= 0 {
            withAnimation(.easeInOut(duration: 0.2)) {
                currentStep = ContactFormStep.allCases[prevIndex]
            }
        }
    }
}

// MARK: - Form Components

struct SectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.moltPrimary)
            
            Text(title)
                .font(.moltBody)
                .fontWeight(.semibold)
                .foregroundColor(.moltTextPrimary)
        }
    }
}

struct FormCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(Spacing.lg)
            .background(Color.moltSurface)
            .cornerRadius(CornerRadius.medium)
    }
}

struct FormTextField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var isRequired: Bool = false
    var keyboardType: KeyboardType = .default
    
    enum KeyboardType {
        case `default`, phone, email
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: 4) {
                Text(label)
                    .font(.moltLabel)
                    .foregroundColor(.moltTextSecondary)
                
                if isRequired {
                    Text("*")
                        .foregroundColor(.priorityUrgent)
                }
            }
            
            TextField(placeholder, text: $text)
                .font(.moltBody)
                .padding(Spacing.sm)
                .background(Color.moltSurfaceSecondary)
                .cornerRadius(CornerRadius.small)
        }
    }
}

struct FormTextArea: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(label)
                .font(.moltLabel)
                .foregroundColor(.moltTextSecondary)
            
            TextEditor(text: $text)
                .font(.moltBody)
                .frame(height: 80)
                .padding(Spacing.xs)
                .background(Color.moltSurfaceSecondary)
                .cornerRadius(CornerRadius.small)
        }
    }
}

struct FormPicker<T: Hashable & CaseIterable & RawRepresentable>: View where T.RawValue == String {
    let label: String
    @Binding var selection: T
    let options: [T]
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(label)
                .font(.moltLabel)
                .foregroundColor(.moltTextSecondary)
            
            Picker("", selection: $selection) {
                ForEach(options, id: \.self) { option in
                    Text(option.rawValue.capitalized)
                        .tag(option)
                }
            }
            .pickerStyle(.segmented)
        }
    }
}

// MARK: - Student Components

struct EmptyStudentCard: View {
    let onAdd: () -> Void
    
    var body: some View {
        Button(action: onAdd) {
            VStack(spacing: Spacing.md) {
                ZStack {
                    Circle()
                        .fill(Color.moltPrimaryLight)
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "plus")
                        .font(.system(size: 24))
                        .foregroundColor(.moltPrimary)
                }
                
                Text("Add a Child/Student")
                    .font(.moltBody)
                    .foregroundColor(.moltTextPrimary)
                
                Text("Add information about children enrolled at the school")
                    .font(.moltCaption)
                    .foregroundColor(.moltTextMuted)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(Spacing.xl)
            .background(Color.moltSurface)
            .cornerRadius(CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.medium)
                    .stroke(Color.moltDivider, style: StrokeStyle(lineWidth: 2, dash: [8]))
            )
        }
        .buttonStyle(.plain)
    }
}

struct StudentCard: View {
    let student: StudentFormData
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(Color.moltPrimary.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Image(systemName: "person.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.moltPrimary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(student.name)
                    .font(.moltBody)
                    .fontWeight(.medium)
                    .foregroundColor(.moltTextPrimary)
                
                Text("\(student.grade) \(student.classSection.isEmpty ? "" : "• Class \(student.classSection)")")
                    .font(.moltCaption)
                    .foregroundColor(.moltTextSecondary)
            }
            
            Spacer()
            
            HStack(spacing: Spacing.sm) {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.system(size: 14))
                        .foregroundColor(.moltTextSecondary)
                }
                .buttonStyle(.plain)
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundColor(.priorityUrgent)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(Spacing.md)
        .background(Color.moltSurface)
        .cornerRadius(CornerRadius.medium)
    }
}

struct AddMoreStudentButton: View {
    let onAdd: () -> Void
    
    var body: some View {
        Button(action: onAdd) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.moltPrimary)
                Text("Add Another Child")
                    .font(.moltBody)
                    .foregroundColor(.moltPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(Spacing.md)
            .background(Color.moltPrimaryLight)
            .cornerRadius(CornerRadius.medium)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Review Components

struct ReviewInfoRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.moltTextMuted)
                .frame(width: 20)
            
            Text(label)
                .font(.moltCaption)
                .foregroundColor(.moltTextMuted)
                .frame(width: 80, alignment: .leading)
            
            Text(value)
                .font(.moltBody)
                .foregroundColor(.moltTextPrimary)
            
            Spacer()
        }
    }
}

struct StudentReviewRow: View {
    let student: StudentFormData
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(Color.moltPrimary.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Text(student.name.prefix(1).uppercased())
                    .font(.moltBody)
                    .fontWeight(.medium)
                    .foregroundColor(.moltPrimary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(student.name)
                    .font(.moltBody)
                    .fontWeight(.medium)
                    .foregroundColor(.moltTextPrimary)
                
                HStack(spacing: Spacing.md) {
                    Label(student.grade, systemImage: "graduationcap")
                    if !student.classSection.isEmpty {
                        Label("Class \(student.classSection)", systemImage: "person.3")
                    }
                    if !student.admissionNumber.isEmpty {
                        Label(student.admissionNumber, systemImage: "number")
                    }
                }
                .font(.moltCaption)
                .foregroundColor(.moltTextSecondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Add Student Sheet
struct AddStudentSheet: View {
    @Binding var isPresented: Bool
    let onSave: (StudentFormData) -> Void
    
    @State private var name = ""
    @State private var grade = "JSS1"
    @State private var classSection = ""
    @State private var admissionNumber = ""
    @State private var dateOfBirth = Date()
    @State private var gender: Student.Gender = .male
    
    let grades = ["JSS1", "JSS2", "JSS3", "SS1", "SS2", "SS3"]
    let classSections = ["A", "B", "C", "D"]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: { isPresented = false }) {
                    Text("Cancel")
                        .font(.moltBody)
                        .foregroundColor(.moltTextSecondary)
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Text("Add Child")
                    .font(.moltTitleSmall)
                    .foregroundColor(.moltTextPrimary)
                
                Spacer()
                
                Button(action: saveStudent) {
                    Text("Add")
                        .font(.moltBody)
                        .fontWeight(.medium)
                        .foregroundColor(name.isEmpty ? .moltTextMuted : .moltPrimary)
                }
                .buttonStyle(.plain)
                .disabled(name.isEmpty)
            }
            .padding(Spacing.lg)
            .background(Color.moltSurface)
            
            SubtleDivider()
            
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    FormCard {
                        VStack(spacing: Spacing.lg) {
                            FormTextField(
                                label: "Child's Full Name",
                                placeholder: "e.g., Tunde Adeyemi",
                                text: $name,
                                isRequired: true
                            )
                            
                            HStack(spacing: Spacing.md) {
                                VStack(alignment: .leading, spacing: Spacing.xs) {
                                    Text("Grade/Class")
                                        .font(.moltLabel)
                                        .foregroundColor(.moltTextSecondary)
                                    
                                    Picker("", selection: $grade) {
                                        ForEach(grades, id: \.self) { g in
                                            Text(g).tag(g)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .frame(maxWidth: .infinity)
                                    .padding(Spacing.sm)
                                    .background(Color.moltSurfaceSecondary)
                                    .cornerRadius(CornerRadius.small)
                                }
                                
                                VStack(alignment: .leading, spacing: Spacing.xs) {
                                    Text("Section")
                                        .font(.moltLabel)
                                        .foregroundColor(.moltTextSecondary)
                                    
                                    Picker("", selection: $classSection) {
                                        Text("Select").tag("")
                                        ForEach(classSections, id: \.self) { s in
                                            Text(s).tag(s)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .frame(maxWidth: .infinity)
                                    .padding(Spacing.sm)
                                    .background(Color.moltSurfaceSecondary)
                                    .cornerRadius(CornerRadius.small)
                                }
                            }
                            
                            FormTextField(
                                label: "Admission Number",
                                placeholder: "e.g., ADM/2024/001",
                                text: $admissionNumber
                            )
                            
                            VStack(alignment: .leading, spacing: Spacing.xs) {
                                Text("Gender")
                                    .font(.moltLabel)
                                    .foregroundColor(.moltTextSecondary)
                                
                                Picker("", selection: $gender) {
                                    Text("Male").tag(Student.Gender.male)
                                    Text("Female").tag(Student.Gender.female)
                                }
                                .pickerStyle(.segmented)
                            }
                            
                            VStack(alignment: .leading, spacing: Spacing.xs) {
                                Text("Date of Birth")
                                    .font(.moltLabel)
                                    .foregroundColor(.moltTextSecondary)
                                
                                DatePicker("", selection: $dateOfBirth, displayedComponents: .date)
                                    .datePickerStyle(.compact)
                                    .labelsHidden()
                            }
                        }
                    }
                }
                .padding(Spacing.xl)
            }
            .background(Color.moltBackground)
        }
        .frame(width: 450, height: 500)
    }
    
    func saveStudent() {
        let student = StudentFormData(
            name: name,
            grade: grade,
            classSection: classSection,
            admissionNumber: admissionNumber,
            dateOfBirth: dateOfBirth,
            gender: gender
        )
        onSave(student)
        isPresented = false
    }
}

// MARK: - Add Contact Button (for ContactsView)
struct AddContactButton: View {
    @State private var showAddContact = false
    
    var body: some View {
        Button(action: { showAddContact = true }) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(.moltPrimary)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showAddContact) {
            AddContactView(isPresented: $showAddContact)
        }
    }
}
