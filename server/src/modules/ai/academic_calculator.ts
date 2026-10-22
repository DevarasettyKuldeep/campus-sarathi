import type { AcademicAssignment, AcademicClass } from './types.js';

export interface AttendanceMetrics {
  percentage: number | null;
  safeToSkipNext: boolean | null;
  classesNeededForMinimum: number | null;
}

export function calculateAttendanceMetrics(
  attended: number,
  conducted: number,
  minimumPercentage: number | null
): AttendanceMetrics {
  if (conducted <= 0) {
    return {
      percentage: null,
      safeToSkipNext: null,
      classesNeededForMinimum: null,
    };
  }

  const percentage = (attended / conducted) * 100;

  if (minimumPercentage === null || minimumPercentage <= 0 || minimumPercentage > 100) {
    return {
      percentage,
      safeToSkipNext: null,
      classesNeededForMinimum: null,
    };
  }

  const ifMissedNext = (attended / (conducted + 1)) * 100;
  const safeToSkipNext = ifMissedNext >= minimumPercentage;

  let classesNeededForMinimum: number | null = null;
  if (percentage < minimumPercentage) {
    const minRatio = minimumPercentage / 100;
    if (minRatio < 1.0) {
      const needed = Math.ceil((minRatio * conducted - attended) / (1.0 - minRatio));
      classesNeededForMinimum = Math.max(1, needed);
    } else {
      classesNeededForMinimum = null; // 100% impossible if already missed one
    }
  }

  return {
    percentage,
    safeToSkipNext,
    classesNeededForMinimum,
  };
}

export function sortPendingAssignments(assignments: AcademicAssignment[]): {
  urgent: AcademicAssignment[];
  upcoming: AcademicAssignment[];
  completed: AcademicAssignment[];
} {
  const pending = assignments.filter((a) => !a.complete);
  const completed = assignments.filter((a) => a.complete);

  const now = new Date();
  const threeDaysFromNow = new Date(now.getTime() + 3 * 24 * 60 * 60 * 1000);

  const sortedPending = [...pending].sort((a, b) => {
    return new Date(a.dueAt).getTime() - new Date(b.dueAt).getTime();
  });

  const urgent: AcademicAssignment[] = [];
  const upcoming: AcademicAssignment[] = [];

  for (const item of sortedPending) {
    const due = new Date(item.dueAt);
    if (due <= threeDaysFromNow) {
      urgent.push(item);
    } else {
      upcoming.push(item);
    }
  }

  return { urgent, upcoming, completed };
}

export function getTodayClasses(classes: AcademicClass[], date: Date = new Date()): AcademicClass[] {
  // JavaScript getDay() returns 0 for Sunday, 1 for Monday...
  // Our system: 1 = Monday, ..., 7 = Sunday
  const jsDay = date.getDay();
  const weekday = jsDay === 0 ? 7 : jsDay;

  return classes
    .filter((c) => c.weekday === weekday)
    .sort((a, b) => a.startMinute - b.startMinute);
}
